#include <sys/socket.h>
#include "syscall.h"

int shutdown(int fd, int how)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_shutdown, fd, how);
#elif defined(__linux__)
	return socketcall(shutdown, fd, how, 0, 0, 0, 0);
#endif
}
