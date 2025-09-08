/* OpenBSD Stage-1: getcwd(3) via SYS___getcwd.
 *
 * Minimal wrapper used during bootstrap (static, no ldso).
 * Behavior for buf==NULL is not supported in stage-1.
 */
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include "syscall.h"

char *getcwd(char *buf, size_t size)
{
	if (!buf || !size) {
		errno = EINVAL;
		return 0;
	}
#ifdef SYS___getcwd
	long r = __syscall(SYS___getcwd, buf, size);
	if (__syscall_ret(r) < 0)
		return 0;
	return buf;
#else
	errno = ENOSYS;
	return 0;
#endif
}
