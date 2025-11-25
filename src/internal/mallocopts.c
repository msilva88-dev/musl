#include <sys/mman.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "libc.h"
#include "mallocopts.h"

hidden struct __mallocopts {
	uint16_t mo_cachesize: 3; // >/< - cache size exponent (2**n * 1KB)
	uint16_t mo_canaries: 1; // C/c - enable heap canaries
	uint16_t mo_dump: 1; // D/d - dump stats to malloc.out
	uint16_t mo_freecheck: 1; // F/f - check double-free/use-after-free
	uint16_t mo_freeunmap: 1; // U/u - unmap freed large allocations
	uint16_t mo_guard: 1; // G/g - use guard pages
	uint16_t mo_junklev: 2; // J/j - junk fill level 0..2
	uint16_t mo_mutexes: 3; // +/- - thread mutex pool level 0..5
	uint16_t mo_realloc: 1; // R/r - always reallocate on realloc()
	uint16_t mo_xmalloc: 1; // X/x - abort on OOM
	uint16_t __pad: 1;
} __mallocopts = { .mo_cachesize = 6 /* 64KB (2**6) */, .mo_junklev = 1, .mo_mutexes = 3 /* 8 (2**3) */ };

// delayed-chunks for junk/free checking
#define MAX_DELAYED_CHUNKS 64
hidden struct __delayed_chunk {
	void *addr;
	size_t len;
	uint64_t when;
} __delayed_chunks[MAX_DELAYED_CHUNKS];
hidden int __delayed_count = 0;
static volatile int __delayed_list_lock[2] = { 0, 0 };
#define DELAYED_PROTECT_THRESHOLD PAGE_SIZE
/* Delay before inspecting freed chunks (seconds) */
#define DELAYED_CHUNK_DELAY_SEC 1

static struct __guard_entry {
	void *base; // mmap base (include front guard)
	size_t total; // total mapped bytes = aligned + 2*PAGE_SIZE
	struct __guard_entry *next;
	volatile int ref; // reference count (atomic ops)
	volatile int removed; // 0 = in-list, 1 = removed
} *__guard_list = NULL;
static volatile int __guard_list_lock[2] = { 0, 0 };

// Add quarantine structure for guarded frees
static struct __guard_quarantine {
	void *base;
	size_t total;
	uint64_t when;
	struct __guard_quarantine *next;
} *__guard_q = NULL;
static volatile int __guard_q_lock[2] = {0,0};

static volatile int mallocopts_initialized = 0;
void check_malloc_options_once()
{
	// idempotent init; simple parsing from MALLOC_OPTIONS or malloc_options if present
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
			if (__mallocopts.mo_mutexes < 5) ++__mallocopts.mo_mutexes;
			break;
		case '<':
			if (__mallocopts.mo_cachesize > 0) --__mallocopts.mo_cachesize;
			break;
		case '>':
			if (__mallocopts.mo_cachesize < 8) ++__mallocopts.mo_cachesize;
			break;
		case 'C':
			__mallocopts.mo_canaries = 1;
			break;
		case 'D':
			__mallocopts.mo_dump = 1;
			break;
		case 'F':
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
		}
	}
}

static inline void m_crash(const char *const msg)
{
	size_t n = 0;
	while (msg[n]) n++;
	write(2, msg, n);
	a_crash();
}

static inline void m_warn(const char *const msg)
{
	size_t n = 0;
	while (msg[n]) n++;
	write(2, msg, n);
}

/* lock/unlock helpers — accept pointer to two-int array (element 0 = lock, element 1 = waiter counter) */

static inline void lock(int (*arr)[2])
{
	// wait: CAS on element 0, and wait on (addr0, addr1) as original futex helpers expect
	while (a_cas(&(*arr)[0], 0, 1)) __wait(&(*arr)[0], &(*arr)[1], 1, 1);
}

static inline void unlock(int (*arr)[2])
{
	// swap element0 back to 0; if previous value was 1 wake sleepers.
	// a_swap returns the *previous* value. wake only if previous == 1.
	if (a_swap(&(*arr)[0], 0) == 1) __wake(&(*arr)[0], 1, 1);
}

static int add_guard_entry(void *base, size_t total)
{
	struct __guard_entry *g = mmap(NULL, sizeof(*g), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (g == MAP_FAILED) return -1;
	// explicit init to avoid any uninitialized fields/races
	g->base = base;
	g->total = total;
	g->next = NULL;
	g->removed = 0;
	g->ref = 1; // list itself holds one reference
	lock(&__guard_list_lock);
	g->next = __guard_list;
	__guard_list = g;
	unlock(&__guard_list_lock);
	return 0;
}

static inline uint64_t monotonic_seconds(void)
{
	struct timespec ts;
	if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
		/* Fall back to wall clock to avoid indefinite suppression of checks. */
		time_t t = time(NULL);
		return (uint64_t)(t >= 0 ? t : 0);
	}
	return (uint64_t)ts.tv_sec;
}

static void guard_quarantine_add(void *base, size_t total)
{
	struct __guard_quarantine *n = mmap(NULL, sizeof(*n), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (n == MAP_FAILED) return;
	n->base = base;
	n->total = total;
	n->when = monotonic_seconds();
	lock(&__guard_q_lock);
	n->next = __guard_q;
	__guard_q = n;
	unlock(&__guard_q_lock);
}

static void guard_quarantine_sweep(uint64_t now)
{
	lock(&__guard_q_lock);
	struct __guard_quarantine **pp = &__guard_q;
	while (*pp) {
		struct __guard_quarantine *q = *pp;
		if (now - q->when >= DELAYED_CHUNK_DELAY_SEC) {
			*pp = q->next;
			unlock(&__guard_q_lock);

			// remove guard list entry before unmapping to prevent stale list UAF
			if (remove_guard_entry(q->base) != 0) {
				m_warn("malloc: quarantine sweep could not remove guard entry\n");
			}
			// basic sanity check on size (optional): skip absurd totals
			if (q->total == 0 || q->total > SIZE_MAX / 2) {
				m_warn("malloc: quarantine sweep suspicious total size, skipping unmap\n");
			} else {
				munmap(q->base, q->total);
			}

			munmap(q, sizeof(*q));
			lock(&__guard_q_lock);
			continue;
		}
		pp = &q->next;
	}
	unlock(&__guard_q_lock);
}

static void check_delayed_chunks()
{
	// Strategy: gather candidates under lock (and remove them from the
	// shared array), then perform mprotect/inspection *without* holding the lock.
	// This avoids doing slow or re-entrant ops while the list lock is held.
	uint64_t now = monotonic_seconds();

	// local snapshot buffer (small, MAX_DELAYED_CHUNKS constant)
	struct __delayed_chunk snap[MAX_DELAYED_CHUNKS];
	int snap_count = 0;

	lock(&__delayed_list_lock);
	for (int i = 0; i < __delayed_count; ) {
		struct __delayed_chunk *d = &__delayed_chunks[i];
		if (now < d->when || (now - d->when) < DELAYED_CHUNK_DELAY_SEC) {
			i++;
			continue;
		}
		// snapshot the chunk now
		snap[snap_count++] = *d;
		// remove entry by swapping with last and shrink count
		__delayed_chunks[i] = __delayed_chunks[--__delayed_count];
		// do NOT increment i because we swapped a new element into i
	}
	unlock(&__delayed_list_lock);

	// process snapshots without holding the list lock
	for (int s = 0; s < snap_count; s++) {
		unsigned char *ptr = (unsigned char *)snap[s].addr;
		size_t check_len = snap[s].len > 4096 ? 4096 : snap[s].len;
		int need_reprotect = 0;

		if (__mallocopts.mo_freecheck && __mallocopts.mo_freeunmap && snap[s].len >= DELAYED_PROTECT_THRESHOLD) {
			uintptr_t page_base = (uintptr_t)ptr & ~(PAGE_SIZE - 1);
			if (snap[s].len > SIZE_MAX - (uintptr_t)ptr - (PAGE_SIZE - 1)) {
				/* Overflow scenario: treat as suspicious */
				m_crash("malloc: delayed chunk length overflow\n");
			}
			size_t prot_len = ((((uintptr_t)ptr + snap[s].len) - page_base + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1));
			/* If we cannot temporarily make it readable, skip inspection to avoid a crash. */
			if (mprotect((void*)page_base, prot_len, PROT_READ) == 0) need_reprotect = 1;
			else {
				m_warn("malloc: skipped UAF check (mprotect failed)\n");
				continue;
			}
		}

		int bad = 0;
		for (size_t j = 0; j < check_len; j++) {
			if (ptr[j] != JUNK_PATTERN_FREE) {
				bad = 1;
				break;
			}
		}

		if (need_reprotect) {
			uintptr_t page_base = (uintptr_t)ptr & ~(PAGE_SIZE - 1);
			if (snap[s].len > SIZE_MAX - (uintptr_t)ptr - (PAGE_SIZE - 1)) {
				/* Overflow scenario: treat as suspicious */
				m_crash("malloc: delayed chunk length overflow\n");
			}
			size_t prot_len = ((((uintptr_t)ptr + snap[s].len) - page_base + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1));
			(void)mprotect((void*)page_base, prot_len, PROT_NONE);
		}

		if (bad) m_crash("malloc: use-after-free detected\n");
	}
	// Sweep guarded quarantine after chunk checks
	guard_quarantine_sweep(now);
}

static inline void guard_hold(struct __guard_entry *g)
{
	// increment reference (atomic)
	a_inc(&g->ref);
}

static void guard_release(struct __guard_entry *g)
{
	// Atomically decrement the refcount and free the list node only
	// when the previous value was 1 *and* it has been marked removed.
	// Using a_fetch_add keeps the behaviour consistent with the rest
	// of the atomic helpers.
	int prev = a_fetch_add(&g->ref, -1);
	if (prev <= 0) m_crash("guard_release (from malloc): the reference of guard is zero or negative\n");
	// decrement and free only if previous value was 1 (so new becomes 0)
	if (prev == 1 && g->removed) munmap(g, sizeof(*g));
}

static struct __guard_entry *find_guard_by_ptr(void *ptr)
{
	if (!ptr) return NULL;
	uintptr_t p = (uintptr_t)ptr;
	lock(&__guard_list_lock);
	struct __guard_entry *g = __guard_list;
	while (g) {
		// skip obviously removed nodes quickly
		if (g->removed) {
			g = g->next;
			continue;
		}

		// take a stable reference
		a_inc(&g->ref);

		// if removed raced in, drop it and restart scan from head
		if (g->removed) {
			guard_release(g);
			g = __guard_list;
			continue;
		}

		// compute usable range while we still own g
		uintptr_t user_base = (uintptr_t)g->base + PAGE_SIZE;
		size_t usable = g->total - 2*PAGE_SIZE; // usable, page-aligned
		uintptr_t user_end = user_base + usable;

		if (usable != 0 && user_end >= user_base && p >= user_base && p < user_end) {
			// found: keep caller reference and return (unlock first)
			unlock(&__guard_list_lock);
			return g;
		}

		// not ours: advance. capture next before releasing current reference
		struct __guard_entry *next = g->next;
		if (next) a_inc(&next->ref);
		guard_release(g);
		g = next;
	}
	unlock(&__guard_list_lock);
	return NULL;
}

static int remove_guard_entry(void *base)
{
	if (!base) return -1;
	lock(&__guard_list_lock);
	struct __guard_entry **pp = &__guard_list;
	while (*pp) {
		if ((*pp)->base == base) {
			struct __guard_entry *old = *pp;
			*pp = old->next;
			// mark removed while still holding lock to prevent races
			old->removed = 1;
			unlock(&__guard_list_lock);

			// drop the list's reference
			//if (a_fetch_add(&old->ref, -1) == 1) munmap(old, sizeof(*old));
			guard_release(old);
			return 0;
		}
		pp = &(*pp)->next;
	}
	unlock(&__guard_list_lock);
	return -1;
}

/* Helper for overflow: check (base + add) ((PAGE_SIZE - 1) included) */
static inline int plus_overflows_with_rounding(uintptr_t base, size_t add)
{
	if (
		(add > (SIZE_MAX - base))
		|| ((PAGE_SIZE - 1) && add + (PAGE_SIZE - 1) > (SIZE_MAX - base))
	) return 1;
	return 0;
}

void fill_junk(void *p, size_t len, int on_alloc)
{
	if (!p || len == 0) return;
	check_malloc_options_once();
	if (on_alloc && __mallocopts.mo_junklev < 2) return;
	else if (!__mallocopts.mo_junklev) return;

	unsigned char val = on_alloc ? JUNK_PATTERN_ALLOC : JUNK_PATTERN_FREE;

	if (__mallocopts.mo_junklev == 2) {
		memset(p, val, len);
		return;
	}

	// level 1: write up to a page for speed
	if (len < PAGE_SIZE) memset(p, val, len);
	else memset(p, val, PAGE_SIZE);
}

/* freecheck: validate alignment only */
void freecheck(void *p)
{
	if (!p) return;
	check_malloc_options_once();
	if (!__mallocopts.mo_freecheck) return;

	uintptr_t addr = (uintptr_t)p;
	if (addr % sizeof(void*) != 0) m_crash("free(): invalid pointer alignment\n");
}

// mguard: allocate region; if guard option enabled, create 2 guard pages
// around an aligned interior region. Return pointer to user area (map + PAGE) on success.
// For CONCEAL flag on supported OSes, attempt optimizations.
void *mguard(size_t size, int flags)
{
	if (size == 0) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

	check_malloc_options_once();

	// if guard pages disabled, fall back to plain mmap; but still honour CONCEAL on some OS
	if (!__mallocopts.mo_guard) {
		if (flags & MCHUNK_FLAG_CONCEAL) {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
			return mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_CONCEAL, -1, 0);
#elif defined(__linux__)
			void *map = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
			if (map == MAP_FAILED) return MAP_FAILED;
			mlock(map, size);
			madvise(map, size, MADV_DONTDUMP);
			return map;
#endif
		}
		return mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	}

	// aligned size to page
	size_t aligned = size;
	if (size & (PAGE_SIZE - 1)) aligned = (size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
	if (aligned > SIZE_MAX - 2*PAGE_SIZE) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

	size_t total = aligned + 2*PAGE_SIZE;
	void *base = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (base == MAP_FAILED) return MAP_FAILED;

	void *front_guard = base;
	void *map = (char *)base + PAGE_SIZE;
	void *rear_guard = (char *)base + PAGE_SIZE + aligned;

	if ((mprotect(front_guard, PAGE_SIZE, PROT_NONE) != 0) || (mprotect(rear_guard, PAGE_SIZE, PROT_NONE) != 0)) {
		int serrno = errno;
		munmap(base, total);
		errno = serrno;
		return MAP_FAILED;
	}

	if (add_guard_entry(base, total) != 0) {
		int serrno = errno;

		mprotect(front_guard, PAGE_SIZE, PROT_READ | PROT_WRITE);
		mprotect(rear_guard, PAGE_SIZE, PROT_READ | PROT_WRITE);
		munmap(base, total);
		errno = serrno ? serrno : ENOMEM;
		return MAP_FAILED;
	}

	return map;
}

// munguard: given user pointer and size (user length), undo guard mapping and unmap
int munguard(void *ptr, size_t size)
{
	if (ptr == NULL || size == 0) return 0; // no-op

	check_malloc_options_once();

	if (!__mallocopts.mo_guard) return munmap(ptr, size);

	struct __guard_entry *g = find_guard_by_ptr(ptr);
	if (!g) {
		errno = EINVAL;
		return -1;
	}

	size_t usable = g->total - 2*PAGE_SIZE;
	if (size > usable) {
		guard_release(g);
		errno = EINVAL;
		return -1;
	}

	void *base = g->base;
	size_t total = g->total;

	// remove from list first (this drops the list reference). Then
	// release the caller reference. This avoids using g->base after g
	// might have been destroyed.
	if (remove_guard_entry(base) != 0) {
		errno = EINVAL;
		return -1;
	}

	guard_release(g);

	(void)mprotect(base, PAGE_SIZE, PROT_READ | PROT_WRITE);
	size_t aligned = total - 2*PAGE_SIZE;
	(void)mprotect((char *)base + PAGE_SIZE + aligned, PAGE_SIZE, PROT_READ | PROT_WRITE);

	return munmap(base, total);
}

// mreguard: resize guarded region. On Linux try mremap fast-path; otherwise allocate new guarded region, copy, replace list
void *mreguard(void *ptr, size_t old_size, size_t new_size)
{
	if (!ptr || old_size == 0 || new_size == 0) {
		errno = EINVAL;
		return MAP_FAILED;
	}

	check_malloc_options_once();

	if (!__mallocopts.mo_guard) {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		void *newp = mmap(NULL, new_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		if (newp == MAP_FAILED) return MAP_FAILED;

		memcpy(newp, ptr, (new_size < old_size) ? new_size : old_size);
		munmap(ptr, old_size);
		return newp;
#elif defined(__linux__)
		return mremap(ptr, old_size, new_size, MREMAP_MAYMOVE);
#endif
	}

	// must be a registered guard region
	struct __guard_entry *g = find_guard_by_ptr(ptr);
	if (!g) {
		errno = EINVAL;
		return MAP_FAILED;
	}

	size_t old_aligned = g->total - 2*PAGE_SIZE;
	size_t old_total = g->total;
	char *old_base = g->base;
	// keep caller ref 'g' while we update the guard list/entries

	// calculates align for new_size
	size_t new_aligned = (new_size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);

	if (new_aligned > SIZE_MAX - 2*PAGE_SIZE) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

	size_t new_total = new_aligned + 2*PAGE_SIZE;
	if (new_total < new_aligned) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

#if defined(__linux__)
	// try mremap on the whole base region
	char *new_base = mremap(old_base, old_total, new_total, MREMAP_MAYMOVE);
	if (new_base != MAP_FAILED) {
		// protect new guard pages on the new mapping
		(void)mprotect(new_base, PAGE_SIZE, PROT_NONE);
		(void)mprotect(new_base + PAGE_SIZE + new_aligned, PAGE_SIZE, PROT_NONE);

		// add the new guard entry first (so we don't lose metadata on failure)
		if (add_guard_entry(new_base, new_total) != 0) {
			(void)mprotect(new_base, PAGE_SIZE, PROT_READ | PROT_WRITE);
			(void)mprotect(new_base + PAGE_SIZE + new_aligned, PAGE_SIZE, PROT_READ | PROT_WRITE);
			munmap(new_base, new_total);
			errno = ENOMEM;
			guard_release(g);
			return MAP_FAILED;
		}

		// remove the old entry after successfully adding the new one
		if (remove_guard_entry(old_base) != 0) {
			// unexpected: try to clean up the new entry and fail
			remove_guard_entry(new_base);
			munmap(new_base, new_total);
			errno = EINVAL;
			guard_release(g);
			return MAP_FAILED;
		}

		// release caller ref and return user pointer
		guard_release(g);
		return new_base + PAGE_SIZE;
	}
#endif
	// fallback: allocate new guarded region, copy, register, remove old
	char *new_base2 = mmap(NULL, new_total, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (new_base2 == MAP_FAILED) return MAP_FAILED;

	memcpy(new_base2 + PAGE_SIZE, ptr, (new_size < old_size) ? new_size : old_size);
	if (
		(mprotect(new_base2, PAGE_SIZE, PROT_NONE) != 0)
		|| (mprotect(new_base2 + PAGE_SIZE + new_aligned, PAGE_SIZE, PROT_NONE) != 0)
	) {
		int serrno = errno;
		munmap(new_base2, new_total);
		errno = serrno;
		return MAP_FAILED;
	}

	if (add_guard_entry(new_base2, new_total) != 0) {
		int serrno = errno;
		// cleanup
		mprotect(new_base2, PAGE_SIZE, PROT_READ | PROT_WRITE);
		mprotect(new_base2 + PAGE_SIZE + new_aligned, PAGE_SIZE, PROT_READ | PROT_WRITE);
		munmap(new_base2, new_total);
		errno = serrno ? serrno : ENOMEM;
		guard_release(g);
		return MAP_FAILED;
	}

	// remove old metadata and unmap old region. If removal fails, undo new entry
	if (remove_guard_entry(old_base) != 0) {
		// best-effort: remove the new entry we added and cleanup
		remove_guard_entry(new_base2);
		munmap(new_base2, new_total);
		errno = EINVAL;
		guard_release(g);
		return MAP_FAILED;
	}

	munmap(old_base, old_total);
	guard_release(g);
	return new_base2 + PAGE_SIZE;
}

void register_delayed_chunk(void *p, size_t len)
{
	if (!p || len == 0) return;
	check_malloc_options_once();
	if (!__mallocopts.mo_junklev) return;
	lock(&__delayed_list_lock);
	if (__delayed_count >= MAX_DELAYED_CHUNKS) {
		// Avoid deadlock: don't call check_delayed_chunks() while we
		// hold __delayed_list_lock (that function acquires the same lock).
		// Unlock, optionally run cleaner, then re-lock and re-check.
		unlock(&__delayed_list_lock);
		// Optional probabilistic cleanup to reduce contention:
		// only run occasionally to avoid CPU storm.
		if ((arc4random() & 0x0F) == 0) check_delayed_chunks();
		// re-acquire lock and re-evaluate; if still full give up
		lock(&__delayed_list_lock);
		if (__delayed_count >= MAX_DELAYED_CHUNKS) {
			unlock(&__delayed_list_lock);
			return;
		}
	}
	__delayed_chunks[__delayed_count].addr = p;
	__delayed_chunks[__delayed_count].len = len;
	__delayed_chunks[__delayed_count].when = monotonic_seconds();
	__delayed_count++;
	unlock(&__delayed_list_lock);
	if (__mallocopts.mo_freecheck && __mallocopts.mo_freeunmap && len >= DELAYED_PROTECT_THRESHOLD) {
		uintptr_t page_base = (uintptr_t)p & ~(PAGE_SIZE - 1);
		/* Overflow check includes rounding addition (PAGE_SIZE - 1) */
		if (len > SIZE_MAX - (uintptr_t)p - (PAGE_SIZE - 1)) m_crash("free(): overflow found in freecheck\n");
		size_t prot_len = ((((uintptr_t)p + len) - page_base + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1));
		(void)mprotect((void*)page_base, prot_len, PROT_NONE);
	}
	if ((arc4random() & 0x0F) == 0) check_delayed_chunks();
}

void protect_chunk(void *p, size_t size)
{
	if (!p || size == 0) return;
	check_malloc_options_once();
	if (!__mallocopts.mo_freeunmap) return;
	if (size >= FREEUNMAP_THRESHOLD) {
		uintptr_t base = (uintptr_t)p & ~(PAGE_SIZE - 1);
		/* Overflow check for end computation */
		if (plus_overflows_with_rounding((uintptr_t)p, size)) m_crash("protect_chunk (from malloc): overflow\n");
		uintptr_t end = ((uintptr_t)p + size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
		if (end < (uintptr_t)p) m_crash("protect_chunk (from malloc): end < p overflow\n");
		size_t plen = end - base;
		(void)mprotect((void*)base, plen, PROT_NONE);
	}
}

void unprotect_chunk(void *p, size_t size)
{
	if (!p || size == 0) return;
	check_malloc_options_once();
	if (!__mallocopts.mo_freeunmap) return;
	if (size >= FREEUNMAP_THRESHOLD) {
		uintptr_t base = (uintptr_t)p & ~(PAGE_SIZE - 1);
		if (plus_overflows_with_rounding((uintptr_t)p, size)) m_crash("unprotect_chunk (from malloc): overflow\n");
		uintptr_t end = ((uintptr_t)p + size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
		if (end < (uintptr_t)p) m_crash("unprotect_chunk (from malloc): end < p overflow\n");
		size_t plen = end - base;
		(void)mprotect((void*)base, plen, PROT_READ | PROT_WRITE);
	}
}

// free_chunk: free an mchunk-allocated area (user pointer)
void free_chunk(void *p)
{
	if (!p) return;

	// try to see if this pointer is a 'mchunk' allocation
	struct __mchunk *m = mchunk_from_user(p);
	if (!m) m_crash("free(): invalid pointer\n");
	if (m->magic == MCHUNK_MAGIC_FREED) m_crash("free(): double free detected\n");
	if (m->magic != MCHUNK_MAGIC) m_crash("free(): invalid or corrupted pointer\n");
	freecheck(p);
	/* Mark as freed with a sentinel to allow double-free detection. */
	m->magic = MCHUNK_MAGIC_FREED;
	if (m->flags & MCHUNK_FLAG_CONCEAL) explicit_bzero(p, m->user_len);
	else fill_junk(p, m->user_len, 0);
	// delayed free handling: register for delayed checking/protection
	register_delayed_chunk(p, m->user_len);
	if (m->flags & MCHUNK_FLAG_GUARD) {
		// Mark freed, protect for UAF, then quarantine for delayed full unmap
		protect_chunk(p, m->user_len);
		guard_quarantine_add(m->base ? m->base : (void*)m, m->total_len);
		return;
	}
	// unmap the region: use stored base/total_len if present, else treat m as base
	munmap(m->base ? m->base : (void *)m, m->total_len);
}

// free_mchunk: attempt to free pointer if it's a mchunk; return 1 if handled
int free_mchunk(void *p)
{
	if (!p) return 1; // free(NULL);

	// try to see if this pointer is a 'mchunk' allocation
	struct __mchunk *m = mchunk_from_user(p);
	if (m && m->magic == MCHUNK_MAGIC) {
		free_chunk(p);
		return 1;
	}
	if (m && m->magic == MCHUNK_MAGIC_FREED) m_crash("free(): double free detected\n");
	return 0;
}

// malloc_chunk: allocate an mchunk (returns user pointer)
void *malloc_chunk(size_t size, int flags)
{
	if (size > SIZE_MAX - sizeof(struct __mchunk)) {
		errno = ENOMEM;
		return NULL;
	}
	size_t mlen = size + sizeof(struct __mchunk);
	check_malloc_options_once();
	size_t aligned = __mallocopts.mo_guard ? (mlen + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1) : mlen;
	void *map = mguard(aligned, flags);
	if (map == MAP_FAILED) return NULL;
	// sanity: if metadata doesn't fit inside aligned region -> cleanup
	if (sizeof(struct __mchunk) + size > aligned) {
		int serrno = ENOMEM;
		if (__mallocopts.mo_guard) {
			void *base = (char *)map - PAGE_SIZE;
			size_t total = aligned + 2*PAGE_SIZE;
			munmap(base, total);
		} else {
			munmap(map, aligned);
		}
		errno = serrno;
		return NULL;
	}
	struct __mchunk *m = (struct __mchunk *)map;
	m->magic = MCHUNK_MAGIC;
	m->user_len = size;
	m->flags = __mallocopts.mo_guard ? flags | MCHUNK_FLAG_GUARD : flags;
	// fetch guard entry if present to store real base/total for munmap later
	struct __guard_entry *g = find_guard_by_ptr(map);
	if (__mallocopts.mo_guard && g) {
		m->base = g->base;
		m->total_len = g->total;
		guard_release(g);
	} else {
		m->base = map;
		m->total_len = aligned;
	}
	void *p = (char *)m + sizeof(struct __mchunk);
	fill_junk(p, size, 1);
	return p;
}

// realloc_chunk: attempt to grow/shrink; uses mreguard fast-path for guarded regions
void *realloc_chunk(void *old, size_t newlen, int flags)
{
	if (!old) return malloc_chunk(newlen, flags);
	if (newlen == 0) {
		free_chunk(old);
		return NULL;
	}

	struct __mchunk *m = mchunk_from_user(old);
	if (!m) m_crash("realloc(): invalid pointer\n");
	if (m->magic == MCHUNK_MAGIC_FREED) m_crash("realloc(): double free detected\n");
	if (m->magic != MCHUNK_MAGIC) m_crash("realloc(): invalid or corrupted pointer\n");

	size_t oldlen = m->user_len;
	size_t old_total = m->total_len;
	int old_flags = m->flags;

	if (newlen == oldlen) {
		check_malloc_options_once();
		if (!__mallocopts.mo_realloc) return old;
		// otherwise fall through and reallocate
	}

	// shrink in-place
	if (newlen < oldlen) {
		// wipe sensitive data first (CONCEAL must always zero)
		if (old_flags & MCHUNK_FLAG_CONCEAL) explicit_bzero((char *)old + newlen, oldlen - newlen);
		// then optionally fill with junk according to options
		else fill_junk((char *)old + newlen, oldlen - newlen, 0);
		m->user_len = newlen;
		return old;
	}

#if defined(__linux__)
	if (old_flags & MCHUNK_FLAG_GUARD) {
		// try to grow in-place for guarded regions on linux via mreguard (fast path)
		void *r = mreguard(old, m->user_len, newlen);
		if (r != MAP_FAILED) {
			// mreguard returns the user pointer (map + PAGE) on success in your design
			// update m->user_len if metadata needs it: find new mchunk and set
			struct __mchunk *nm = mchunk_from_user(r);
			if (nm && nm->magic == MCHUNK_MAGIC) {
				nm->user_len = newlen;
				nm->flags = old_flags;
			}
			return r;
		}
	}
#endif

	// fallback: allocate, copy, free
	void *newp = malloc_chunk(newlen, old_flags);
	if (!newp) return NULL;

	size_t ncopy = oldlen < newlen ? oldlen : newlen;
	if (old_flags & MCHUNK_FLAG_CONCEAL) explicit_bzero((char*)old + ncopy, oldlen - ncopy);
	memcpy(newp, old, ncopy);

	// free will explicit_bzero if conceal flag set (free_chunk handles it)
	free_chunk(old);
	return newp;
}
