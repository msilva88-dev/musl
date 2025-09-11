/* OpenBSD stage-1:
 * Some libc objects (e.g. fstat.o) reference the internal symbol
 * __fstatat. Provide a trivial shim that forwards to fstatat so
 * we can link static tests without pulling in time64/thread glue.
 */
#ifdef MUSL_OBSD
#include <sys/stat.h>

__attribute__((visibility("hidden")))
int __fstatat(int fd, const char *path, struct stat *st, int flag)
{
	return fstatat(fd, path, st, flag);
}
#endif
