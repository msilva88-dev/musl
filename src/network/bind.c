#include <sys/socket.h>
#include "syscall.h"

int bind(int fd, const struct sockaddr *addr, socklen_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_bind, fd, addr, len);
#elif defined(__linux__)
	return socketcall(bind, fd, addr, len, 0, 0, 0);
#endif
}
