#define _BSD_SOURCE
#include <unistd.h>
#include <stdint.h>
#include <errno.h>
#include "syscall.h"

extern char _end;
static void *__curbrk = &_end;

void *sbrk(intptr_t inc)
{
	void *oldbrk = __curbrk;

	if ((char *)oldbrk + inc < &_end || brk((char *)oldbrk + inc) != 0)
		return (errno = ENOMEM, (void *)-1);

	return __curbrk = (char *)oldbrk + inc, oldbrk;
}
