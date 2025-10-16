#include <signal.h>
#include <errno.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

int sigwait(const sigset_t *restrict mask, int *restrict sig)
{
	siginfo_t si;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	sigset_t ss = *mask;

	sigdelset(&ss, SIGTHR);
	for (;;) {
		si.si_signo = syscall_cp(SYS___thrsigdivert, ss, NULL, NULL);
		if (si.si_signo == -1 && errno == EINTR) continue;
		break;
	}

	if (si.si_signo < 0) return errno;
#elif defined(__linux__)
	if (sigtimedwait(mask, &si, 0) < 0) return errno;
#endif
	*sig = si.si_signo;
	return 0;
}
