#include <stdio.h>
#include "syscall.h"

int renameat(int oldfd, const char *old, int newfd, const char *new)
{
#if defined(SYS_renameat) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_renameat, oldfd, old, newfd, new);
#else
	return syscall(SYS_renameat2, oldfd, old, newfd, new, 0);
#endif
}
