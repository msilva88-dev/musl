#define _GNU_SOURCE
#include <unistd.h>
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
	int r = sysctl((int[]){ CTL_KERN, KERN_DOMAINNAME }, 2, NULL, NULL, name, len);
	if (r == -1) return -1;
#elif defined(__linux__)
	return syscall(SYS_setdomainname, name, len);
#endif
}
