#include <sys/stat.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

int mkfifo(const char *path, mode_t mode)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_mkfifo, path, mode);
#elif defined(__linux__)
	return mknod(path, mode | S_IFIFO, 0);
#endif
}
