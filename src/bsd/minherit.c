#define _BSD_SOURCE
#include <sys/mman.h>
#include "syscall.h"

int minherit(void *addr, size_t len, int inherit)
{
	return syscall(SYS_minherit, addr, len, inherit);
}
