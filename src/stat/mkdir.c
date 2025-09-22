#include <sys/stat.h>
#include <fcntl.h>
#include "syscall.h"

int mkdir(const char *path, mode_t mode)
{
#if defined(SYS_mkdir) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_mkdir, path, mode);
#else
	return syscall(SYS_mkdirat, AT_FDCWD, path, mode);
#endif
}
