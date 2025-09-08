/* OpenBSD Stage-1: implement times(3) without SYS_times.
 *
 * Fill struct tms using getrusage(2) and return elapsed "ticks" from
 * CLOCK_MONOTONIC. Return (clock_t)-1 on failure, like POSIX.
 */
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/times.h>
#include <time.h>
#include <unistd.h>

static inline clock_t tv_to_ticks(const struct timeval *tv, long hz)
{
	/* convert seconds+usec to clock ticks, truncating toward zero */
	return (clock_t)(tv->tv_sec * hz + (tv->tv_usec * hz) / 1000000L);
}

static inline clock_t ts_to_ticks(const struct timespec *ts, long hz)
{
	/* convert seconds+nsec to clock ticks, truncating toward zero */
	return (clock_t)(ts->tv_sec * hz + (ts->tv_nsec * hz) / 1000000000L);
}

clock_t times(struct tms *t)
{
	long hz = sysconf(_SC_CLK_TCK);
	if (hz <= 0) hz = 100; /* safe default */

	if (t) {
		struct rusage self, kids;
		if (getrusage(RUSAGE_SELF, &self) < 0) return (clock_t)-1;
		if (getrusage(RUSAGE_CHILDREN, &kids) < 0) return (clock_t)-1;

		t->tms_utime  = tv_to_ticks(&self.ru_utime, hz);
		t->tms_stime  = tv_to_ticks(&self.ru_stime, hz);
		t->tms_cutime = tv_to_ticks(&kids.ru_utime, hz);
		t->tms_cstime = tv_to_ticks(&kids.ru_stime, hz);
	}

	struct timespec now;
	if (clock_gettime(CLOCK_MONOTONIC, &now) < 0)
		return (clock_t)-1;

	return ts_to_ticks(&now, hz);
}
