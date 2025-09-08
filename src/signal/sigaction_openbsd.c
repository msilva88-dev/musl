#include <signal.h>
#include "syscall.h"

/* Thin wrapper over the native sigaction(2) syscall. */
int sigaction(int sig, const struct sigaction *sa, struct sigaction *old)
{
	long r = __syscall(SYS_sigaction, sig, sa, old);
	return __syscall_ret(r);
}
