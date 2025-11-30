#include <sys/mman.h>
#include <errno.h>
#ifdef MALLOC_STATS
#include <inttypes.h>
#endif
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "atomic.h"
#include "libc.h"
#include "mchunk.h"
#include "mallocopts.h"

static struct __mallocopts {
	/* Bit layout for __mallocopts in a uint16_t storage unit (must total 16):
	 * mo_cachesize: 4
	 * mo_canaries:  1
	 * mo_dump:      1
	 * mo_freecheck: 1
	 * mo_freeunmap: 1
	 * mo_guard:     1
	 * mo_junklev:   2
	 * mo_mutexes:   3
	 * mo_realloc:   1
	 * mo_xmalloc:   1
	 */
	/* mo_cachesize: Free page cache capacity exponent (capacity = (1<<n)*1KB).
	 * Adjusted via '<' (decrement) and '>' (increment).
	 * Widened to 4 bits (0..8) to allow exponent=8 (256KB). */
	uint16_t mo_cachesize: 4;
	/* mo_canaries: 'C' enable / 'c' disable heap canaries. */
	uint16_t mo_canaries: 1;
	/* mo_dump: 'D' enable / 'd' disable dump of stats to ./malloc.out at exit. */
	uint16_t mo_dump: 1;
	/* mo_freecheck: 'F' enable / 'f' disable more extensive double-free/UAF checks.
	 * NOTE (divergence): Page protection on frees engages here only when combined
	 * with mo_freeunmap 'U' to reduce overhead. */
	uint16_t mo_freecheck: 1;
	/* mo_freeunmap: 'U' enable / 'u' disable UAF protections for larger frees. */
	uint16_t mo_freeunmap: 1;
	/* mo_guard: 'G' enable / 'g' disable guard pages for eligible allocations. */
	uint16_t mo_guard: 1;
	/* mo_junklev: 'J' increment up to 2, 'j' decrement down to 0.
	 * 0: no junk fill; 1: free-time (up to 1 page); 2: alloc+free full region. */
	uint16_t mo_junklev: 2;
	/* mo_mutexes: '+' increment / '-' decrement shard exponent for page cache buckets.
	 * Active bucket count = 1 << min(mo_mutexes, 5), clamped at 32. */
	uint16_t mo_mutexes: 3;
	/* mo_realloc: 'R' enable / 'r' disable “always reallocate” realloc policy. */
	uint16_t mo_realloc: 1;
	/* mo_xmalloc: 'X' enable / 'x' disable crash-on-OOM instead of returning NULL. */
	uint16_t mo_xmalloc: 1;
} __mallocopts = { .mo_cachesize = 6 /* 64KB (2**6) */, .mo_junklev = 1, .mo_mutexes = 3 /* 8 (2**3) */ };

/* Compile-time sanity checks (requires C11) */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(uint16_t) == 2, "Expected 16-bit storage unit for __mallocopts fields");
_Static_assert(sizeof(__mallocopts) == 2, "__mallocopts must remain 2 bytes; bitfield drift detected");
#endif

static volatile int mallocopts_initialized = 0;

static void warn_malloc_options(char c)
{
	char ubuf[64];
	int ln = snprintf(ubuf, sizeof ubuf,
		"malloc [check_malloc_options_once]: unknown char '%c' in MALLOC_OPTIONS\n", c);
	if (ln > 0) write(2, ubuf, (size_t)ln);
}

static void check_malloc_options_once()
{
	/* Parse options once, honoring letter-order precedence:
	 * later letters override earlier ones.
	 * Supported letters (OBSD-inspired):
	 *   + / - : increase/decrease shard exponent (mo_mutexes)
	 *   < / > : halve/double page cache capacity exponent (1KB units)
	 *   C / c : canaries on/off
	 *   D / d : dump stats at exit on/off (if MALLOC_STATS)
	 *   F / f : freecheck on/off (see divergence note in 'F' handler)
	 *   G / g : guard pages for eligible allocations on/off
	 *   J / j : junk level ++/-- (bounded 0..2)
	 *   R / r : realloc policy always reallocate on/off
	 *   S / s : macro-like “hardening preset”: enable/disable a group
	 *            (implemented here as direct toggles; no sysctl; see code)
	 *   U / u : unmap/protect larger frees on/off
	 *   X / x : xmalloc crash-on-OOM on/off
	 * Unknown letters produce a warning. */

	/* Idempotent init; simple parsing from MALLOC_OPTIONS or malloc_options if present */
	if (a_cas(&mallocopts_initialized, 0, 1) != 0) return;

	const char *env = getenv("MALLOC_OPTIONS"), *p;

	if (env && *env) p = env;
	else if (malloc_options && *malloc_options) p = malloc_options;
	else return;

	for (; *p; p++) {
		switch (*p) {
		case '-':
			if (__mallocopts.mo_mutexes > 0) --__mallocopts.mo_mutexes;
			break;
		case '+':
			/* increment mutexes exponent up to 5 (3-bit field) */
			if (__mallocopts.mo_mutexes < 5) ++__mallocopts.mo_mutexes;
			break;
		case '<':
			if (__mallocopts.mo_cachesize > 0) --__mallocopts.mo_cachesize;
			break;
		case '>':
			/* increment cache exponent up to 8 (4-bit field) */
			if (__mallocopts.mo_cachesize < 8) ++__mallocopts.mo_cachesize;
			break;
		case 'C':
			__mallocopts.mo_canaries = 1;
			break;
		case 'D':
			__mallocopts.mo_dump = 1;
			break;
		case 'F':
			/* Divergence from OBSD doc: we engage page protection for UAF
			 * only when both F (freecheck) and U (freeunmap) are enabled.
			 * This reduces overhead while keeping UAF detection robust. */
			__mallocopts.mo_freecheck = 1;
			__mallocopts.mo_freeunmap = 1;
			break;
		case 'G':
			__mallocopts.mo_guard = 1;
			break;
		case 'J':
			if (__mallocopts.mo_junklev < 2) ++__mallocopts.mo_junklev;
			break;
		case 'R':
			__mallocopts.mo_realloc = 1;
			break;
		case 'S':
			__mallocopts.mo_canaries = 1;
			__mallocopts.mo_freecheck = 1;
			__mallocopts.mo_freeunmap = 1;
			__mallocopts.mo_guard = 1;
			if (__mallocopts.mo_junklev < 2) ++__mallocopts.mo_junklev;
			break;
		case 'U':
			__mallocopts.mo_freeunmap = 1;
			break;
		case 'X':
			__mallocopts.mo_xmalloc = 1;
			break;
		case 'c':
			__mallocopts.mo_canaries = 0;
			break;
		case 'd':
			__mallocopts.mo_dump = 0;
			break;
		case 'f':
			__mallocopts.mo_freecheck = 0;
			__mallocopts.mo_freeunmap = 0;
			break;
		case 'g':
			__mallocopts.mo_guard = 0;
			break;
		case 'j':
			if (__mallocopts.mo_junklev > 0) --__mallocopts.mo_junklev;
			break;
		case 'r':
			__mallocopts.mo_realloc = 0;
			break;
		case 's':
			__mallocopts.mo_canaries = 0;
			__mallocopts.mo_freecheck = 0;
			__mallocopts.mo_freeunmap = 0;
			__mallocopts.mo_guard = 0;
			if (__mallocopts.mo_junklev > 0) --__mallocopts.mo_junklev;
			break;
		case 'u':
			__mallocopts.mo_freeunmap = 0;
			break;
		case 'x':
			__mallocopts.mo_xmalloc = 0;
			break;
		default:
			warn_malloc_options(*p);
			break;
		}
	}
}

static void m_crash(const char *const msg)
{
	size_t n = 0;
	while (msg[n]) n++;
	write(2, msg, n);
	a_crash();
}

int check_xmalloc(void *mem, const char *msg)
{
	if (!mem) {
		check_malloc_options_once();
		if (__mallocopts.mo_xmalloc) {
			if (!msg) msg = "malloc() [check_xmalloc]: allocation failed\n";
			m_crash(msg);
		}
		return ENOMEM;
	}
	return 0;
}
