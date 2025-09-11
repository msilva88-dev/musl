/* OpenBSD Stage-1: statx(2) is not available. Provide an ENOSYS stub
 * so callers can probe and fall back to fstat/fstatat/lstat as needed. */
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

struct statx; /* forward; the declaration lives in <sys/stat.h> on Linux */

int statx(int dirfd, const char *path, int flags,
          unsigned int mask, struct statx *buf)
{
	(void)dirfd; (void)path; (void)flags; (void)mask; (void)buf;
	errno = ENOSYS;
	return -1;
}
