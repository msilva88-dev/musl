#define _BSD_SOURCE
#include <sys/stat.h>
#include <fcntl.h>
#include "syscall.h"

int chflags(const char *path, unsigned int flags)
{
	return syscall(SYS_chflags, path, flags);
}

int chflagsat(int fd, const char *path, unsigned int flags, int atflags)
{
	return syscall(SYS_chflagsat, fd, path, flags, atflags);
}

int fchflags(int fd, unsigned int flags)
{
	return syscall(SYS_fchflags, fd, flags);
}
