#include <unistd.h>
#include "syscall.h"

int pipe(int fd[2])
{
#if defined(SYS_pipe) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_pipe, fd);
#else
	return syscall(SYS_pipe2, fd, 0);
#endif
}
