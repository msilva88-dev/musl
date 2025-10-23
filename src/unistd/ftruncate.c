#include <unistd.h>
#include "syscall.h"

int ftruncate(int fd, off_t length)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_ftruncate, fd, 0, __SYSCALL_LL_O(length));
#elif defined(__linux__)
	return syscall(SYS_ftruncate, fd, __SYSCALL_LL_O(length));
#endif
}
