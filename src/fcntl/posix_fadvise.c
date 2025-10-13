#include <fcntl.h>
#if defined(__linux__)
#include "syscall.h"
#elif defined(__HyperbolaBSD__)
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#endif

int posix_fadvise(int fd, off_t base, off_t len, int advice)
{
#if defined(__linux__)
#if defined(SYSCALL_FADVISE_6_ARG)
	/* Some archs, at least arm and powerpc, have the syscall
	 * arguments reordered to avoid needing 7 argument registers
	 * due to 64-bit argument alignment. */
	return -__syscall(SYS_fadvise, fd, advice,
		__SYSCALL_LL_E(base), __SYSCALL_LL_E(len));
#else
	return -__syscall(SYS_fadvise, fd, __SYSCALL_LL_O(base),
		__SYSCALL_LL_E(len), advice);
#endif
#elif defined(__HyperbolaBSD__)
	base = __SYSCALL_LL_E(base);
	len  = __SYSCALL_LL_E(len);

	if (len == 0) {
		struct stat st;
		if (fstat(fd, &st) < 0) return errno;

		if (base >= st.st_size) return 0;

		len = st.st_size - base;
	} else if (len <= 0) {
		return 0;
	}

	int prot = PROT_NONE;
	int madvise_flag;
	switch(advice) {
		case POSIX_FADV_NOREUSE:
		case POSIX_FADV_NORMAL:
			return 0;
		case POSIX_FADV_SEQUENTIAL:
			madvise_flag = MADV_SEQUENTIAL;

			break;
		case POSIX_FADV_RANDOM:
			madvise_flag = MADV_RANDOM;

			break;
		case POSIX_FADV_WILLNEED:
			madvise_flag = MADV_WILLNEED;
			prot = PROT_READ;

			break;
		case POSIX_FADV_DONTNEED:
			madvise_flag = MADV_DONTNEED;

			break;
		default:
			return EINVAL;
	}

	long pagesize = sysconf(_SC_PAGESIZE);
	if (pagesize <= 0) pagesize = 4096;

	off_t end = base + len;
	if (end < base) return EOVERFLOW;

	off_t aligned_base = base & ~(pagesize - 1);
	size_t aligned_len = end - aligned_base;

	void *addr = mmap(
		NULL,
		aligned_len,
		prot,
		MAP_SHARED,
		fd,
		aligned_base
	);
	// mmap failed: POSIX mandates we return errno
	if (addr == MAP_FAILED) return errno;

	int ret = madvise(addr, aligned_len, madvise_flag);
	munmap(addr, aligned_len);

	return ret;
#endif
}
