#define _GNU_SOURCE
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include "libc.h"

// vmsplice_wrapper

ssize_t vmsplice(int fd, const struct iovec *iov, size_t cnt, unsigned flags)
{
	struct stat st;
	if (fstat(fd, &st) < 0) return -1;

	if (!S_ISFIFO(st.st_mode)) {
		errno = EINVAL;
		return -1;
	}

	ssize_t total = 0;
	for (size_t i = 0; i < cnt; i++) {
		const char *buf = iov[i].iov_base;
		size_t len = iov[i].iov_len;
		size_t offset = 0;

		if (flags & SPLICE_F_GIFT) {
			if (((uintptr_t)buf % PAGE_SIZE) != 0 || (len % PAGE_SIZE) != 0) {
				errno = EINVAL;
				return -1;
			}
			if (mprotect((void *)buf, len, PROT_READ) < 0) return -1;
		}

		while (offset < len) {
			ssize_t m = write(fd, buf + offset, len - offset);
			if (m < 0) {
				if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) {
					return total > 0 ? total : -1;
				}
				if (errno == EINTR) continue;
				return -1;
			}
			if (m == 0) break;
			offset += m;
			total += m;
			if (flags & SPLICE_F_MORE);
		}
	}

	return total;
}
