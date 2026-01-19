#define _BSD_SOURCE
#include <sys/mman.h>
#include "syscall.h"

int msyscall(void *addr, size_t len)
{
	return syscall(SYS_msyscall, addr, len);
}
