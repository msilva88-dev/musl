#include <poll.h>
#include <time.h>
#include <signal.h>
#include "syscall.h"

int poll(struct pollfd *fds, nfds_t n, int timeout)
{
#if defined(SYS_poll) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_poll, fds, n, timeout);
#else
#if SYS_ppoll_time64 == SYS_ppoll
	typedef long long ppoll_ts_t[2];
#else
	typedef long ppoll_ts_t[2];
#endif
	return syscall_cp(SYS_ppoll, fds, n, timeout>=0 ?
		((ppoll_ts_t){ timeout/1000, timeout%1000*1000000 }) : 0,
		0, _NSIG/8);
#endif
}
