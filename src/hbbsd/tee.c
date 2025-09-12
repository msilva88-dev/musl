#define _GNU_SOURCE
#include <errno.h>
#include <stddef.h>
#include <unistd.h>

// tee_wrapper

ssize_t tee(
	int src,
	int dest,
	size_t len,
	unsigned flags __attribute__((unused))
)
{
	(void)flags;
	char buf[4096];
	ssize_t n, w, total = 0, written = 0;

	while (total < (ssize_t)len) {
		n = read(
			src,
			buf,
			(len - total > sizeof(buf))
			? sizeof(buf) : len - total
		);

		if (n <= 0) {
			if (errno == EINTR) {
				continue; // Retry
			}

			return -1;
		} else if (n == 0) {
			break; // EOF
		}

		while (written < n) {
			w = write(dest, buf + written, n - written);

			if (w < 0) {
				if (errno == EINTR) {
					continue; // Retry
				}

				return -1;
			}

			written += w;
		}

		total += n;
	}

	return total;
}
