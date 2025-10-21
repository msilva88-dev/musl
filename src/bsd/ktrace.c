#define _BSD_SOURCE
#include <sys/uio.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/ktrace.h>
#elif defined(__OpenBSD__)
#include <sys/ktrace.h>
#endif
#include "syscall.h"

int ktrace(const char *tracefile, int ops, int trpoints, pid_t pid);
{
	return syscall(SYS_ktrace, tracefile, ops, trpoints, pid);
}

int utrace(const char *label, void *addr, size_t len)
{
	return syscall(SYS_utrace, label, addr, len);
}
