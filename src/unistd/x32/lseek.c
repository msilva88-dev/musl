#include <unistd.h>
#include "syscall.h"

off_t __lseek(int fd, off_t offset, int whence)
{
	off_t ret;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	register long r10 __asm__("r10") = whence;
	__asm__ __volatile__ ("syscall"
		: "=a"(ret)
		: "a"(SYS_lseek), "D"(fd), "d"(offset), "S"(0), "r"(r10)
		: "rcx", "r11", "memory");
#elif defined(__linux__)
	__asm__ __volatile__ ("syscall"
		: "=a"(ret)
		: "a"(SYS_lseek), "D"(fd), "S"(offset), "d"(whence)
		: "rcx", "r11", "memory");
#endif
	return ret < 0 ? __syscall_ret(ret) : ret;
}

weak_alias(__lseek, lseek);
