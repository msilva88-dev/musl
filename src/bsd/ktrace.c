#define _BSD_SOURCE
#include <sys/param.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <signal.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/ktrace.h>
#elif defined(__OpenBSD__)
#include <sys/ktrace.h>
#endif
#include "syscall.h"

int ktrace(const char *tracefile, int ops, int trpoints, pid_t pid)
{
	return syscall(SYS_ktrace, tracefile, ops, trpoints, pid);
}

int utrace(const char *label, const void *addr, size_t len)
{
	return syscall(SYS_utrace, label, addr, len);
}
