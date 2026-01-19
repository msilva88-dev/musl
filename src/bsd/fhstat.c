#define _BSD_SOURCE
#include <sys/types.h>
#include <sys/mount.h>
#include "syscall.h"

int fhstat(const fhandle_t *fhp, struct stat *st)
{
	return syscall(SYS_fhstat, fhp, st);
}
