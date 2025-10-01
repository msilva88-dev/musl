#define _BSD_SOURCE
#include <sys/mount.h>
#include "syscall.h"

int getfsstat(struct statfs *buf, size_t bufsize, int flags)
{
	return syscall(SYS_getfsstat, buf, bufsize, flags);
}
