#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int getdtablecount(void)
{
	return syscall(SYS_getdtablecount);
}
