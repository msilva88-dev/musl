#include <sys/mman.h>
#include "syscall.h"

int mlock(const void *addr, size_t len)
{
#if defined(SYS_mlock) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_mlock, addr, len);
#else
	return syscall(SYS_mlock2, addr, len, 0);
#endif
}
