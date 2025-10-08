#include <fcntl.h>
#include <stdarg.h>
#include "syscall.h"

int openat(int fd, const char *filename, int flags, ...)
{
	mode_t mode = 0;

	if (
		(flags & O_CREAT)
#if defined(__linux__)
		|| (flags & O_TMPFILE) == O_TMPFILE
#endif
	) {
		va_list ap;
		va_start(ap, flags);
		mode = va_arg(ap, mode_t);
		va_end(ap);
	}

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_openat, fd, filename, flags, mode);
#elif defined(__linux__)
	return syscall_cp(SYS_openat, fd, filename, flags|O_LARGEFILE, mode);
#endif
}
