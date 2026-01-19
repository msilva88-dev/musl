#define _BSD_SOURCE
#include <sys/types.h>
#include <sys/mount.h>
#include "syscall.h"

int fhstatfs(const fhandle_t *fhp, struct statfs *buf)
{
	return syscall(SYS_fhstatfs, fhp, buf);
}
