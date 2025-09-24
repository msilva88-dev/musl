#define _BSD_SOURCE
#include <unistd.h>
#include <errno.h>
#include "syscall.h"

extern char _end;
static void *__curbrk = &_end, *__minbrk = &_end;

int brk(void *addr)
{
    if (addr < __minbrk || syscall(SYS_break, addr) != 0)
	return (errno = ENOMEM, -1);

    __curbrk = addr;
    return 0;
}
