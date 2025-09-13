#include <fcntl.h>
#if defined(__linux__)
#include "syscall.h"
#elif defined(__HyperbolaBSD__)
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#endif

int posix_fallocate(int fd, off_t base, off_t len)
{
#if defined(__linux__)
	return -__syscall(SYS_fallocate, fd, 0, __SYSCALL_LL_E(base),
		__SYSCALL_LL_E(len));
#elif defined(__HyperbolaBSD__)
	if (len <= 0) {
		return 0;
	}

	struct stat st;
	if (fstat(fd, &st) < 0) {
		return errno;
	}

	off_t end = base + len;

	if (st.st_size >= end) {
		return 0;
	}

	if (ftruncate(fd, end) < 0) {
		return errno;
	}

	if (st.st_size < base) {
		off_t curr = lseek(fd, 0, SEEK_CUR);
		if (curr == (off_t)-1) {
			return errno;
		}

		if (lseek(fd, st.st_size, SEEK_SET) == (off_t)-1) {
			return errno;
		}

		unsigned char buf[4096];
		explicit_bzero(buf, sizeof(buf));
		off_t written = 0;
		off_t to_fill = base - st.st_size;

		while (written < to_fill) {
			size_t w = (to_fill - written < sizeof(buf))
				? to_fill - written : sizeof(buf);
			ssize_t r = write(fd, buf, w);

			if (r < 0) {
				int err = errno;

				lseek(fd, curr, SEEK_SET);

				return err;
			}

			written += r;
		}

		if (lseek(fd, curr, SEEK_SET) == (off_t)-1) return errno;
	}

	return 0;
#endif
}

