#include <unistd.h>
#include "syscall.h"

int truncate(const char *path, off_t length)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_truncate, path, 0, __SYSCALL_LL_O(length));
#elif defined(__linux__)
	return syscall(SYS_truncate, path, __SYSCALL_LL_O(length));
#endif
}
