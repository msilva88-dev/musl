#include <termios.h>
#include <sys/ioctl.h>
#include "syscall.h"

int tcdrain(int fd)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_ioctl, fd, TIOCDRAIN, 0);
#elif defined(__linux__)
	return syscall_cp(SYS_ioctl, fd, TCSBRK, 1);
#endif
}
