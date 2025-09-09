#include <time.h>
#include <errno.h>

/* Minimal __clock_nanosleep: implement via nanosleep.
 * Supports relative sleeps for any clock; supports TIMER_ABSTIME by
 * computing a relative delta from clock_gettime().
 */
int __clock_nanosleep(clockid_t clk, int flags,
                      const struct timespec *req,
                      struct timespec *rem)
{
	if (!req) { errno = EINVAL; return -1; }

	if (!(flags & TIMER_ABSTIME)) {
		return nanosleep(req, rem);
	}

	/* Absolute deadline: sleep(now->deadline) if in the future. */
	struct timespec now, rel;
	if (clock_gettime(clk, &now) < 0) return -1;

	/* rel = *req - now (clamp to zero) */
	rel.tv_sec  = req->tv_sec  - now.tv_sec;
	rel.tv_nsec = req->tv_nsec - now.tv_nsec;
	if (rel.tv_nsec < 0) { rel.tv_nsec += 1000000000L; rel.tv_sec--; }
	if (rel.tv_sec < 0) {
		/* already expired */
		return 0;
	}
	return nanosleep(&rel, rem);
}

/* Optionally export the public symbol too, if needed by apps. */
#if 1
int clock_nanosleep(clockid_t clk, int flags,
                    const struct timespec *req,
                    struct timespec *rem)
{
	return __clock_nanosleep(clk, flags, req, rem);
}
#endif
