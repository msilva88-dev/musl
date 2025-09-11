/* OpenBSD Stage-1: fstatat via native syscall (no statx). */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "syscall.h"

int fstatat(int fd, const char *path, struct stat *st, int flag)
{
#ifdef SYS_fstatat
	long r = __syscall(SYS_fstatat, fd, path, st, flag);
	return __syscall_ret(r);
#else
	/* Should not happen on OpenBSD 7.0; keep a graceful fallback. */
	(void)fd; (void)path; (void)st; (void)flag;
	errno = ENOSYS;
	return -1;
#endif
}
