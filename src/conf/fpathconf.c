#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include <limits.h>
#include <errno.h>
#endif

long fpathconf(int fd, int name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
        return __syscall(SYS_fpathconf, fd, name);
#elif defined(__linux__)
	static const short values[] = {
		[_PC_LINK_MAX] = _POSIX_LINK_MAX,
		[_PC_MAX_CANON] = _POSIX_MAX_CANON,
		[_PC_MAX_INPUT] = _POSIX_MAX_INPUT,
		[_PC_NAME_MAX] = NAME_MAX,
		[_PC_PATH_MAX] = PATH_MAX,
		[_PC_PIPE_BUF] = PIPE_BUF,
		[_PC_CHOWN_RESTRICTED] = 1,
		[_PC_NO_TRUNC] = 1,
		[_PC_VDISABLE] = 0,
		[_PC_SYNC_IO] = 1,
		[_PC_ASYNC_IO] = -1,
		[_PC_PRIO_IO] = -1,
		[_PC_SOCK_MAXBUF] = -1,
		[_PC_FILESIZEBITS] = FILESIZEBITS,
		[_PC_REC_INCR_XFER_SIZE] = 4096,
		[_PC_REC_MAX_XFER_SIZE] = 4096,
		[_PC_REC_MIN_XFER_SIZE] = 4096,
		[_PC_REC_XFER_ALIGN] = 4096,
		[_PC_ALLOC_SIZE_MIN] = 4096,
		[_PC_SYMLINK_MAX] = -1,
		[_PC_2_SYMLINKS] = 1
	};
	if (name >= sizeof(values)/sizeof(values[0])) {
		errno = EINVAL;
		return -1;
	}
	return values[name];
#endif
}
