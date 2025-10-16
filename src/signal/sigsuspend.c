#include <signal.h>
#include "syscall.h"

int sigsuspend(const sigset_t *mask)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	sigset_t ss;

	if (sigismember(mask, SIGTHR)) {
		ss = *mask;
		sigdelset(&ss, SIGTHR);
		mask = &ss;
	}

	return syscall_cp(SYS_sigsuspend, mask);
#elif defined(__linux__)
	return syscall_cp(SYS_rt_sigsuspend, mask, _NSIG/8);
#endif
}
