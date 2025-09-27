#include <signal.h>
#include <stdint.h>
#include "syscall.h"
#include "pthread_impl.h"

int raise(int sig)
{
	sigset_t set;
	__block_app_sigs(&set);
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int ret = syscall(SYS_thrkill, __pthread_self()->tid, sig, NULL);
#elif defined(__linux__)
	int ret = syscall(SYS_tkill, __pthread_self()->tid, sig);
#endif
	__restore_sigs(&set);
	return ret;
}
