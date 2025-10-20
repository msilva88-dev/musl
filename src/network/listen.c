#include <sys/socket.h>
#include "syscall.h"

int listen(int fd, int backlog)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_listen, fd, backlog);
#elif defined(__linux__)
	return socketcall(listen, fd, backlog, 0, 0, 0, 0);
#endif
}
