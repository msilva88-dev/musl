#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include "syscall.h"

int fchdir(int fd)
{
	int ret = __syscall(SYS_fchdir, fd);

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __syscall_ret(ret);
#elif defined(__linux__)
	if (ret != -EBADF || __syscall(SYS_fcntl, fd, F_GETFD) < 0)
		return __syscall_ret(ret);

	char buf[15+3*sizeof(int)];
	__procfdname(buf, fd);
	return syscall(SYS_chdir, buf);
#endif
}
