#include <sys/socket.h>
#include <fcntl.h>
#include <errno.h>
#include "syscall.h"

int socket(int domain, int type, int protocol)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int s = __syscall(SYS_socket, domain, type, protocol);
#elif defined(__linux__)
	int s = __socketcall(socket, domain, type, protocol, 0, 0, 0);
#endif
	if ((s==-EINVAL || s==-EPROTONOSUPPORT)
	    && (type&(SOCK_CLOEXEC|SOCK_NONBLOCK))) {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		s = __syscall(SYS_socket, domain,
			type & ~(SOCK_CLOEXEC|SOCK_NONBLOCK),
			protocol);
#elif defined(__linux__)
		s = __socketcall(socket, domain,
			type & ~(SOCK_CLOEXEC|SOCK_NONBLOCK),
			protocol, 0, 0, 0);
#endif
		if (s < 0) return __syscall_ret(s);
		if (type & SOCK_CLOEXEC)
			__syscall(SYS_fcntl, s, F_SETFD, FD_CLOEXEC);
		if (type & SOCK_NONBLOCK)
			__syscall(SYS_fcntl, s, F_SETFL, O_NONBLOCK);
	}
	return __syscall_ret(s);
}
