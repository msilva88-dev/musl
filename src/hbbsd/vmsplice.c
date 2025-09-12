#define _GNU_SOURCE
#include <errno.h>
#include <unistd.h>
#include <sys/uio.h>

// vmsplice_wrapper

ssize_t vmsplice(
	int fd,
	const struct iovec *iov,
	size_t cnt,
	unsigned flags __attribute__((unused))
)
{
	(void)flags;
	ssize_t w, total = 0;

	for (size_t i = 0; i < cnt; i++) {
		w = write(fd, iov[i].iov_base, iov[i].iov_len);

		if (w < 0) {
			return -1;
		}

		total += w;
	}

	return total;
}
