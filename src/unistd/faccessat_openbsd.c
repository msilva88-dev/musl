/* OpenBSD Stage-1: faccessat via native syscall. */
#include <fcntl.h>
#include <unistd.h>
#include "syscall.h"

int faccessat(int fd, const char *path, int amode, int flags)
{
#ifdef SYS_faccessat
	long r = __syscall(SYS_faccessat, fd, path, amode, flags);
	return __syscall_ret(r);
#else
	/* Should not occur on OpenBSD 7.0; keep a graceful fallback. */
	(void)fd; (void)path; (void)amode; (void)flags;
	errno = ENOSYS;
	return -1;
#endif
}
