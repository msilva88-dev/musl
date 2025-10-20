#include <sys/socket.h>
#include "syscall.h"

int accept(int fd, struct sockaddr *restrict addr, socklen_t *restrict len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_accept, fd, addr, len);
#elif defined(__linux__)
	return socketcall_cp(accept, fd, addr, len, 0, 0, 0);
#endif
}
