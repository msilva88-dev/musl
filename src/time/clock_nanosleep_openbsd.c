/* OpenBSD Stage-1: implement clock_nanosleep() without a syscall.
 * We emulate using clock_gettime(2) and nanosleep(2).
 *
 * Semantics: return 0 on success; on error return the errno value (do not
 * set errno), matching POSIX clock_nanosleep().
 */
#include <time.h>
#include <errno.h>

/* Normalize timespec (nsec in [0, 1e9)). */
static inline void ts_norm(struct timespec *t)
{
	if (t->tv_nsec >= 1000000000L) {
		t->tv_sec  += t->tv_nsec / 1000000000L;
		t->tv_nsec %= 1000000000L;
	} else if (t->tv_nsec < 0) {
		long s = (-t->tv_nsec + 999999999L) / 1000000000L;
		t->tv_sec  -= s;
		t->tv_nsec += s * 1000000000L;
	}
}

static inline void ts_sub(const struct timespec *a,
                          const struct timespec *b,
                          struct timespec *r)
{
	r->tv_sec  = a->tv_sec  - b->tv_sec;
	r->tv_nsec = a->tv_nsec - b->tv_nsec;
	ts_norm(r);
}

static inline int ts_le_zero(const struct timespec *t)
{
	return (t->tv_sec < 0) || (t->tv_sec == 0 && t->tv_nsec <= 0);
}

int clock_nanosleep(clockid_t clk, int flags,
                    const struct timespec *req, struct timespec *rem)
{
	if (!req) return EINVAL;

	/* Relative sleep: just nanosleep and map errno to return value. */
	if (!(flags & TIMER_ABSTIME)) {
		if (nanosleep(req, rem) == 0) return 0;
		return errno;
	}

	/* Absolute time: repeatedly sleep remaining time until deadline or error. */
	for (;;) {
		struct timespec now, delta;
		if (clock_gettime(clk, &now) != 0) return errno;
		ts_sub(req, &now, &delta);
		if (ts_le_zero(&delta)) return 0;  /* already past/at deadline */

		if (nanosleep(&delta, NULL) == 0) return 0;
		if (errno == EINTR) continue;
		return errno;
	}
}
