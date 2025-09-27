#include <signal.h>
#include "syscall.h"

int sigpending(sigset_t *set)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	sigset_t s;

	long ret = __syscall(SYS_sigpending);
	if (ret < 0) return ret;
	if (set) *set = (sigset_t)ret;

	return 0;
#elif defined(__linux__)
	return syscall(SYS_rt_sigpending, set, _NSIG/8);
#endif
}
