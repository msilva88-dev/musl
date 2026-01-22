#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#endif
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <string.h>
#include <limits.h>
#include <stdlib.h> // devname()
#elif defined(__linux__)
#include "syscall.h"
#endif

int ttyname_r(int fd, char *name, size_t size)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct stat st2;
	size_t l;

	if (!isatty(fd)) return errno;

	if (fstat(fd, &st2)) return errno;
	if (!S_ISCHR(st2.st_mode)) return ENOTTY;

	const char *dname = devname(st2.st_rdev, S_IFCHR);
	if (!dname) return ENOTTY;

	l = strlen(dname) + 1;
	if (l > size) return ERANGE;

	memcpy(name, dname, l);
#elif defined(__linux__)
	struct stat st1, st2;
	char procname[sizeof "/proc/self/fd/" + 3*sizeof(int) + 2];
	ssize_t l;

	if (!isatty(fd)) return errno;

	__procfdname(procname, fd);
	l = readlink(procname, name, size);

	if (l < 0) return errno;
	else if (l == size) return ERANGE;

	name[l] = 0;

	if (stat(name, &st1) || fstat(fd, &st2))
		return errno;
	if (st1.st_dev != st2.st_dev || st1.st_ino != st2.st_ino)
		return ENODEV;

#endif
	return 0;
}
