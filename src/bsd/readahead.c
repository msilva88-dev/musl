#define _GNU_SOURCE
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>

ssize_t readahead(int fd, off_t pos, size_t len)
{
	posix_fadvise(fd, pos, len, POSIX_FADV_WILLNEED);

	const size_t block = PAGE_SIZE;
	char buf[PAGE_SIZE];
	size_t total = 0;

	while (total < len) {
		size_t n = len - total;
		if (n > block) n = block;

		ssize_t r = pread(fd, buf, n, pos + total);
		if (r <= 0) {
			if (r == 0) break; // EOF
			if (errno == EINTR) continue;
			return -1;
		}
		total += r;
	}

	return (ssize_t) total;
}
