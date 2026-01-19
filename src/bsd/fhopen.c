#define _BSD_SOURCE
#include <sys/types.h>
#include <sys/mount.h>
#include "syscall.h"

int fhopen(const fhandle_t *fhp, int flags)
{
	return syscall(SYS_fhopen, fhp, flags);
}
