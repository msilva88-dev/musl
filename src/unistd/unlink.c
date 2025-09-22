#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int unlink(const char *path)
{
#if defined(SYS_unlink) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_unlink, path);
#else
	return syscall(SYS_unlinkat, AT_FDCWD, path, 0);
#endif
}
