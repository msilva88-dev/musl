#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int rmdir(const char *path)
{
#if defined(SYS_rmdir) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_rmdir, path);
#else
	return syscall(SYS_unlinkat, AT_FDCWD, path, AT_REMOVEDIR);
#endif
}
