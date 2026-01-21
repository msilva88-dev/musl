#define _GNU_SOURCE
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include <sys/stat.h>
#endif
#include <sys/time.h>

int futimes(int fd, const struct timeval tv[2])
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_futimes, fd, tv);
#elif defined(__linux__)
	struct timespec times[2];
	if (!tv) return futimens(fd, 0);
	times[0].tv_sec  = tv[0].tv_sec;
	times[0].tv_nsec = tv[0].tv_usec * 1000;
	times[1].tv_sec  = tv[1].tv_sec;
	times[1].tv_nsec = tv[1].tv_usec * 1000;
	return futimens(fd, times);
#endif
}
