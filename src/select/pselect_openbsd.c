/* OpenBSD Stage-1: pselect via native syscall. */
#include <sys/types.h>
#include <sys/select.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>
#include "syscall.h"

int pselect(int n,
            fd_set *rfds, fd_set *wfds, fd_set *efds,
            const struct timespec *ts,
            const sigset_t *mask)
{
	long r = __syscall(SYS_pselect, n, rfds, wfds, efds, ts, mask);
	return __syscall_ret(r);
}
