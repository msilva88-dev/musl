#define _GNU_SOURCE
#include <sys/uio.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

// tee_wrapper

ssize_t tee(int src, int dest, size_t len, unsigned flags)
{
	flags &= ~SPLICE_F_GIFT;

	static int pipefd[] = { -1, -1 };
	if (pipefd[0] == -1) {
		if (pipe(pipefd) < 0) return -1;
	}

	ssize_t total = 0;
	while (total < (ssize_t)len) {
		ssize_t n;
		struct iovec iov = { .iov_base = NULL, .iov_len = len - total };
		do {
			n = vmsplice(src, &iov, 1, flags);
		} while (n < 0 && errno == EINTR);

		if (n < 0) {
			if ((flags & SPLICE_F_NONBLOCK) && errno == EAGAIN) break;
			return -1;
		}
		if (n == 0) break;

		ssize_t written = 0;
		while (written < n) {
			ssize_t m;
			do {
				m = splice(pipefd[0], NULL, dest, NULL, n - written, flags);
			} while (m < 0 && errno == EINTR);

			if (m < 0) {
				if ((flags & SPLICE_F_NONBLOCK) && errno == EAGAIN) break;
				return -1;
			}
			written += m;
		}
		total += n;
	}

	return total;
}
