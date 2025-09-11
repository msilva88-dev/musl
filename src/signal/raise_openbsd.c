#include <signal.h>
#include "syscall.h"

/* OpenBSD stage-1: raise(sig) = kill(getpid(), sig). */
int raise(int sig)
{
#ifdef SYS_getpid
	long pid = __syscall(SYS_getpid);
	return __syscall_ret(__syscall(SYS_kill, pid, sig));
#else
	return __syscall_ret(__syscall(SYS_kill, 0, sig));
#endif
}
