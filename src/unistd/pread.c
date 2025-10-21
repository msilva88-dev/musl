#include <unistd.h>
#include "syscall.h"

ssize_t pread(int fd, void *buf, size_t size, off_t ofs)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_pread, fd, buf, size, 0, __SYSCALL_LL_PRW(ofs));
#elif defined(__linux__)
	return syscall_cp(SYS_pread, fd, buf, size, __SYSCALL_LL_PRW(ofs));
#endif
}
