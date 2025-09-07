/* OpenBSD Stage-1: select via native syscall. */
#include <sys/types.h>
#include <sys/select.h>
#include <sys/time.h>
#include <unistd.h>
#include "syscall.h"

int select(int n, fd_set *rfds, fd_set *wfds, fd_set *efds, struct timeval *tv)
{
	long r = __syscall(SYS_select, n, rfds, wfds, efds, tv);
	return __syscall_ret(r);
}
