#define _GNU_SOURCE
#include <fcntl.h>
#include "syscall.h"

// splice_wrapper

ssize_t splice(
	int fd_in,
	off_t *off_in,
	int fd_out,
	off_t *off_out,
	size_t len,
	unsigned flags __attribute__((unused))
{
	(void)flags;
	char buf[8192];
	ssize_t n, total = 0, to_read;

	while (len > 0) {
		to_read = (len < sizeof(buf)) ? len : sizeof(buf);

		if (to_read > len) {
			to_read = len;
		}

		n = pread(fd_in, buf, to_read, off_in ? *off_in : -1);
		if (n <= 0) {
			return (n == 0 && total > 0) ? total : n;
		}

		ssize_t written = 0;
		while (written < n) {
			ssize_t w = pwrite(
				fd_out,
				buf + written,
				n - written,
				off_out ? *off_out : -1
			);

			if (w <= 0) {
				return -1;
			}

			written += w;
		}

		if (off_in) {
			*off_in += n;
		}

		if (off_out) {
			*off_out += n;
		}

		total += n;
		len -= n;
	}

	return total;
}
