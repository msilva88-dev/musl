#include <unistd.h>
#include "syscall.h"

int fdatasync(int fd)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return fsync(fd);
#elif defined(__linux__)
	return syscall_cp(SYS_fdatasync, fd);
#endif
}
