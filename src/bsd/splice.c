#define _GNU_SOURCE
#include <sys/socket.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <unistd.h>

// splice_wrapper

ssize_t splice(int fd_in, off_t *off_in, int fd_out, off_t *off_out, size_t len, unsigned flags)
{
	int pipefd[2];
	if (pipe(pipefd) < 0) return -1;

	ssize_t total = 0;
	while (len > 0) {
		ssize_t chunk = (len < PAGE_SIZE) ? len : PAGE_SIZE;
		ssize_t n;

		for (;;) {
			if (off_in || !isatty(fd_in)) {
				char buf[PAGE_SIZE];
				n = pread(fd_in, buf, chunk, off_in ? *off_in : -1);
				if (n > 0) {
					ssize_t w = write(pipefd[1], buf, n);
					if (w != n) return -1;
				}
			} else {
				n = read(fd_in, buf, chunk);
				if (n > 0) {
					ssize_t w = write(pipefd[1], buf, n);
					if (w != n) return -1;
				}
			}

			if (n < 0) {
				if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) {
					struct pollfd pfd = { fd_in, POLLIN, 0 };
					poll(&pfd, 1, 0);
					continue;
				}
				close(pipefd[0]);
				close(pipefd[1]);
				return -1;
			}
			break;
		}
		if (n == 0) break; // EOF

		ssize_t remaining = n;
		while (remaining > 0) {
			char buf[PAGE_SIZE];
			ssize_t r = read(pipefd[0], buf, remaining);
			if (r <= 0) break;

			ssize_t written = 0;
			while (written < r) {
				ssize_t w;
				if (off_out || !isatty(fd_out)) {
					w = pwrite(fd_out, buf + written, r - written,
					off_out ? *off_out : -1);
				} else {
					int send_flags = 0;
					if (flags & SPLICE_F_MORE) send_flags |= MSG_MORE;
					w = send(fd_out, buf + written, r - written, send_flags);
				}

				if (w < 0) {
					if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) {
						struct pollfd pfd = { fd_out, POLLOUT, 0 };
						poll(&pfd, 1, 0);
						continue;
					}
					close(pipefd[0]);
					close(pipefd[1]);
					return -1;
				}
				written += w;
				if (off_out) *off_out += w;
			}
			remaining -= r;
		}
		if (off_in) *off_in += n;
		total += n;
		len -= n;
	}

	close(pipefd[0]);
	close(pipefd[1]);
	return total;
}
