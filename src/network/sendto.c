#include <sys/socket.h>
#include "syscall.h"

ssize_t sendto(int fd, const void *buf, size_t len, int flags, const struct sockaddr *addr, socklen_t alen)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_sendto, fd, buf, len, flags, addr, alen);
#elif defined(__linux__)
	return socketcall_cp(sendto, fd, buf, len, flags, addr, alen);
#endif
}
