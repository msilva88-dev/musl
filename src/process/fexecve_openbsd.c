/* OpenBSD Stage-1: fexecve() without execveat(2).
 * Prefer the native fexecve(2) syscall; otherwise emulate with /dev/fd/N. */
#include <unistd.h>
#include <errno.h>
#include <sys/syscall.h>
#include "syscall.h"

#include <stdio.h>   /* for snprintf in the fallback */

int fexecve(int fd, char *const argv[], char *const envp[])
{
#ifdef SYS_fexecve
	long r = __syscall(SYS_fexecve, fd, argv, envp);
	return __syscall_ret(r);
#else
	char path[32];
	int n = snprintf(path, sizeof path, "/dev/fd/%d", fd);
	if (n < 0 || n >= (int)sizeof path) {
		errno = EBADF;
		return -1;
	}
	return execve(path, argv, envp);
#endif
}
