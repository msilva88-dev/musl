#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int setlogin(const char *name)
{
	return syscall(SYS_setlogin, name);
}
