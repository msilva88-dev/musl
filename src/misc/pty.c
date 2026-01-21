#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#include <string.h>
#include <unistd.h>
#endif
#include <stdlib.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/tty.h>
#elif defined(__OpenBSD__)
#include <sys/tty.h>
#endif
#include <sys/ioctl.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/stat.h>
#endif
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include "syscall.h"

int posix_openpt(int flags)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	const int AFLAGS = flags & O_ACCMODE, XFLAGS = flags & ~(O_ACCMODE | O_NOCTTY);
	if (AFLAGS != O_RDWR || XFLAGS != 0) {
		errno = EINVAL;
		return -1;
	}
	const int ERR = -1;
	int r = open("/dev/ptm", flags);
	if (r == ERR) return ERR;
	struct ptmget ptm;
	if (ioctl(r, PTMGET, &ptm) != ERR) {
		r = ptm.cfd;
		close(ptm.sfd);
	}
#elif defined(__linux__)
	int r = open("/dev/ptmx", flags);
	if (r < 0 && errno == ENOSPC) errno = EAGAIN;
#endif
	return r;
}

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static int __ptstatus(int fd)
{
	struct stat buf;
	const char *name;
	int err;

	if ((err = __syscall(SYS_fstat, fd, &buf))) return -err;
	name = devname(buf.st_rdev, S_IFCHR);
	if ((err = (!S_ISCHR(buf.st_mode) || strncmp(name, "pty", 3)))) {
		errno = EINVAL;
		return -err;
	}
	return 0;
}
#endif

int grantpt(int fd)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __ptstatus(fd);
#elif defined(__linux__)
	return 0;
#endif
}

int unlockpt(int fd)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __ptstatus(fd);
#elif defined(__linux__)
	int unlock = 0;
	return ioctl(fd, TIOCSPTLCK, &unlock);
#endif
}

int __ptsname_r(int fd, char *buf, size_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct ptmget ptm;
	int err;
#elif defined(__linux__)
	int pty, err;
#endif
	if (!buf) len = 0;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if ((err = __syscall(SYS_ioctl, fd, PTMGET, &ptm))) return -err;
	if (strlcpy(buf, ptm.sn, len) >= len) return ERANGE;
#elif defined(__linux__)
	if ((err = __syscall(SYS_ioctl, fd, TIOCGPTN, &pty))) return -err;
	if (snprintf(buf, len, "/dev/pts/%d", pty) >= len) return ERANGE;
#endif
	return 0;
}

weak_alias(__ptsname_r, ptsname_r);
