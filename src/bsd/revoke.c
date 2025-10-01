#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int revoke(const char *path)
{
	return syscall(SYS_revoke, path);
}
