#define _GNU_SOURCE
#include <unistd.h>
#include <signal.h>
#include "syscall.h"

pid_t vfork(void)
{
	/* vfork syscall cannot be made from C code */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_vfork);
#elif defined(__linux__)
#ifdef SYS_fork
	return syscall(SYS_fork);
#else
	return syscall(SYS_clone, SIGCHLD, 0);
#endif
#endif
}
