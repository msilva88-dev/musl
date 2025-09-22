#include <sys/stat.h>
#include <fcntl.h>
#include "syscall.h"

int mknod(const char *path, mode_t mode, dev_t dev)
{
#if defined(SYS_mknod) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_mknod, path, mode, dev);
#else
	return syscall(SYS_mknodat, AT_FDCWD, path, mode, dev);
#endif
}
