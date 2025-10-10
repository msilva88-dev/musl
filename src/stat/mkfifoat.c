#include <sys/stat.h>
#include <fcntl.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

int mkfifoat(int fd, const char *path, mode_t mode)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_mkfifoat, fd, path, mode);
#elif defined(__linux__)
	return mknodat(fd, path, mode | S_IFIFO, 0);
#endif
}
