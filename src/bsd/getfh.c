#define _BSD_SOURCE
#include <sys/mount.h>
#include "syscall.h"

int getfh(const char *name, fhandle_t *fhp)
{
	return syscall(SYS_getfh, name, fhp);
}
