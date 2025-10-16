#include <signal.h>
#include <errno.h>
#include "syscall.h"

#if defined(__linux__)
#define IS32BIT(x) !((x)+0x80000000ULL>>32)
#define CLAMP(x) (int)(IS32BIT(x) ? (x) : 0x7fffffffU+((0ULL+(x))>>63))
#endif

static int do_sigtimedwait(const sigset_t *restrict mask, siginfo_t *restrict si, const struct timespec *restrict ts)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct timespec tsv;

	if (!ts) return __syscall_cp(SYS___thrsigdivert, mask, si, NULL);
	else {
		tsv = *ts;
		return __syscall_cp(SYS___thrsigdivert, mask, si, &tsv);
	}
#elif defined(__linux__)
#ifdef SYS_rt_sigtimedwait_time64
	time_t s = ts ? ts->tv_sec : 0;
	long ns = ts ? ts->tv_nsec : 0;
	int r = -ENOSYS;
	if (SYS_rt_sigtimedwait == SYS_rt_sigtimedwait_time64 || !IS32BIT(s))
		r = __syscall_cp(SYS_rt_sigtimedwait_time64, mask, si,
			ts ? ((long long[]){s, ns}) : 0, _NSIG/8);
	if (SYS_rt_sigtimedwait == SYS_rt_sigtimedwait_time64 || r!=-ENOSYS)
		return r;
	return __syscall_cp(SYS_rt_sigtimedwait, mask, si,
		ts ? ((long[]){CLAMP(s), ns}) : 0, _NSIG/8);;
#else
	return __syscall_cp(SYS_rt_sigtimedwait, mask, si, ts, _NSIG/8);
#endif
#endif
}

int sigtimedwait(const sigset_t *restrict mask, siginfo_t *restrict si, const struct timespec *restrict timeout)
{
	int ret;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
        sigset_t ssp = *mask;

	sigdelset(&ssp, SIGTHR);
	do ret = do_sigtimedwait(&ssp, si, timeout);
#elif defined(__linux__)
	do ret = do_sigtimedwait(mask, si, timeout);
#endif
	while (ret==-EINTR);
	return __syscall_ret(ret);
}
