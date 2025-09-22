#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int link(const char *existing, const char *new)
{
#if defined(SYS_link) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_link, existing, new);
#else
	return syscall(SYS_linkat, AT_FDCWD, existing, AT_FDCWD, new, 0);
#endif
}
