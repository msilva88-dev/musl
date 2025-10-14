#define _BSD_SOURCE
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include "syscall.h"

int sysctl(
	const int *name,
	unsigned int namelen,
	void *oldp,
	size_t *oldlenp,
	void *newp,
	size_t newlen
)
{
	return syscall(SYS_sysctl, name, namelen, oldp, oldlenp, newp, newlen);
}
