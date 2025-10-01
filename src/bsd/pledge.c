#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int pledge(const char *promises, const char *execpromises)
{
	return syscall(SYS_pledge, promises, execpromises);
}
