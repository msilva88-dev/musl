#include <sys/socket.h>
#include "syscall.h"

int getsockname(int fd, struct sockaddr *restrict addr, socklen_t *restrict len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_getsockname, fd, addr, len);
#elif defined(__linux__)
	return socketcall(getsockname, fd, addr, len, 0, 0, 0);
#endif
}
