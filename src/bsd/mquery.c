#include <sys/mman.h>
#include <errno.h>
#include <stdint.h>
#include "syscall.h"

void *mquery(void *addr, size_t len, int prot, int flags, int fd, off_t off)
{
	if (len >= PTRDIFF_MAX) {
		errno = ENOMEM;
		return MAP_FAILED;
	}

	if (flags & MAP_FIXED) {
		__vm_wait();
	}

	return (void *)__syscall(SYS_mquery, addr, len, prot, flags, fd, 0L, off);
}
