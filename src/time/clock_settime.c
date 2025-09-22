#include <time.h>
#include <errno.h>
#include "syscall.h"

#if defined(__linux__)
#define IS32BIT(x) !((x)+0x80000000ULL>>32)
#endif

int clock_settime(clockid_t clk, const struct timespec *ts)
{
#if defined(SYS_clock_settime64) && defined(__linux__)
	time_t s = ts->tv_sec;
	long ns = ts->tv_nsec;
	int r = -ENOSYS;
	if (SYS_clock_settime == SYS_clock_settime64 || !IS32BIT(s))
		r = __syscall(SYS_clock_settime64, clk,
			((long long[]){s, ns}));
	if (SYS_clock_settime == SYS_clock_settime64 || r!=-ENOSYS)
		return __syscall_ret(r);
	if (!IS32BIT(s))
		return __syscall_ret(-ENOTSUP);
	return syscall(SYS_clock_settime, clk, ((long[]){s, ns}));
#else
	return syscall(SYS_clock_settime, clk, ts);
#endif
}
