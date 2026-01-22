#define _GNU_SOURCE
#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/types.h>
#endif
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#elif defined(__linux__)
#include "syscall.h"
#endif

int setdomainname(const char *name, size_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return sysctl((int[]){ CTL_KERN, KERN_DOMAINNAME }, 2, NULL, NULL, (void *)name, len);
#elif defined(__linux__)
	return syscall(SYS_setdomainname, name, len);
#endif
}
