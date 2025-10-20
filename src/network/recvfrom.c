#include <sys/socket.h>
#include "syscall.h"

ssize_t recvfrom(int fd, void *restrict buf, size_t len, int flags, struct sockaddr *restrict addr, socklen_t *restrict alen)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_recvfrom, fd, buf, len, flags, addr, alen);
#elif defined(__linux__)
	return socketcall_cp(recvfrom, fd, buf, len, flags, addr, alen);
#endif
}
