#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int unveil(const char *path, const char *permissions)
{
	return syscall(SYS_unveil, path, permissions);
}
