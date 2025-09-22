#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int access(const char *filename, int amode)
{
#if defined(SYS_access) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_access, filename, amode);
#else
	return syscall(SYS_faccessat, AT_FDCWD, filename, amode, 0);
#endif
}
