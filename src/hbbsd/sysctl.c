#define _BSD_SOURCE
#include <sys/sysctl.h>
#include "syscall.h"

int sysctl(
	const int *name,
	u_int namelen,
	void *old,
	size_t *oldlenp,
	void *new,
	size_t newlen
)
{
	return syscall(SYS_sysctl, name, namelen, old, oldlenp, new, newlen);
}
