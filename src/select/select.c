#include <sys/select.h>
#include <signal.h>
#include <stdint.h>
#include <errno.h>
#include "syscall.h"

#if defined(__linux__)
#define IS32BIT(x) !((x)+0x80000000ULL>>32)
#define CLAMP(x) (int)(IS32BIT(x) ? (x) : 0x7fffffffU+((0ULL+(x))>>63))
#endif

int select(int n, fd_set *restrict rfds, fd_set *restrict wfds, fd_set *restrict efds, struct timeval *restrict tv)
{
	time_t s = tv ? tv->tv_sec : 0;
	suseconds_t us = tv ? tv->tv_usec : 0;
#if defined(__linux__)
	long ns;
#endif
	const time_t max_time = (1ULL<<8*sizeof(time_t)-1)-1;

	if (s<0 || us<0) return __syscall_ret(-EINVAL);
	if (us/1000000 > max_time - s) {
		s = max_time;
		us = 999999;
#if defined(__linux__)
		ns = 999999999;
#endif
	} else {
		s += us/1000000;
		us %= 1000000;
#if defined(__linux__)
		ns = us*1000;
#endif
	}

#if defined(SYS_pselect6_time64) && defined(__linux__)
	int r = -ENOSYS;
	if (SYS_pselect6 == SYS_pselect6_time64 || !IS32BIT(s))
		r = __syscall_cp(SYS_pselect6_time64, n, rfds, wfds, efds,
			tv ? ((long long[]){s, ns}) : 0,
			((syscall_arg_t[]){ 0, _NSIG/8 }));
	if (SYS_pselect6 == SYS_pselect6_time64 || r!=-ENOSYS)
		return __syscall_ret(r);
	s = CLAMP(s);
#endif
#if defined(SYS_select) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_select, n, rfds, wfds, efds,
		tv ? ((long[]){s, us}) : 0);
#else
	return syscall_cp(SYS_pselect6, n, rfds, wfds, efds,
		tv ? ((long[]){s, ns}) : 0, ((syscall_arg_t[]){ 0, _NSIG/8 }));
#endif
}
