#define _GNU_SOURCE
#include <sys/mman.h>
#include "syscall.h"

int posix_madvise(void *addr, size_t len, int advice)
{
	long ret;

	switch (advice) {
	case MADV_DONTNEED:
	case POSIX_MADV_DONTNEED:
#if defined(__linux__)
		break;
#endif
	case MADV_NORMAL:
	case MADV_RANDOM:
	case MADV_SEQUENTIAL:
	case MADV_WILLNEED:
        case POSIX_MADV_NORMAL:
        case POSIX_MADV_RANDOM:
        case POSIX_MADV_SEQUENTIAL:
        case POSIX_MADV_WILLNEED:
		ret = __syscall(SYS_madvise, addr, len, advice);
		if (ret < 0) return errno;
		break;
	default:
		return EINVAL;
	}

	return 0;
}
