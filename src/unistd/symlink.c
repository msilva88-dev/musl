#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int symlink(const char *existing, const char *new)
{
#if defined(SYS_symlink) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_symlink, existing, new);
#else
	return syscall(SYS_symlinkat, existing, AT_FDCWD, new);
#endif
}
