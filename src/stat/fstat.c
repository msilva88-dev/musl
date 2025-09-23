#define _BSD_SOURCE
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include "syscall.h"

int __fstat(int fd, struct stat *st)
{
	if (fd<0) return __syscall_ret(-EBADF);
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __syscall(SYS_fstat, fd, st);
#elif defined(__linux__)
	return __fstatat(fd, "", st, AT_EMPTY_PATH);
#endif
}

weak_alias(__fstat, fstat);
