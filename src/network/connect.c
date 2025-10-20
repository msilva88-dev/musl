#include <sys/socket.h>
#include "syscall.h"

int connect(int fd, const struct sockaddr *addr, socklen_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_connect, fd, addr, len);
#elif defined(__linux__)
	return socketcall_cp(connect, fd, addr, len, 0, 0, 0);
#endif
}
