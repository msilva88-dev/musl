#define _GNU_SOURCE
#include <sys/socket.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <unistd.h>

// splice_wrapper

#define BUF_SIZE 65536

ssize_t splice(int fd_in, off_t *off_in, int fd_out, off_t *off_out, size_t len, unsigned flags)
{
	struct stat st_in, st_out;
	int fd_in_is_pipe = (fstat(fd_in, &st_in) == 0 && S_ISFIFO(st_in.st_mode));
	int fd_out_is_pipe = (fstat(fd_out, &st_out) == 0 && S_ISFIFO(st_out.st_mode));

	ssize_t total = 0;
	char buf[BUF_SIZE];
	while (total < (ssize_t)len) {
		ssize_t chunk = (len - total < BUF_SIZE) ? len - total : BUF_SIZE;
		ssize_t n = 0;
		if (fd_in_is_pipe && fd_out_is_pipe) {
			n = read(fd_in, buf, chunk);
			if (n <= 0) break;
			ssize_t written = 0;
			while (written < n) {
				ssize_t m = write(fd_out, buf + written, n - written);
				if (m < 0) {
					if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
					if (errno == EINTR) continue;
					return -1;
				}
				written += m;
			}
		} else {
			do {
				if (off_in) n = pread(fd_in, buf, chunk, *off_in);
				else n = read(fd_in, buf, chunk);
			} while (n < 0 && errno == EINTR);

			if (n < 0) {
				if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
				return -1;
			}
			if (n == 0) break;

			ssize_t written = 0;
			while (written < n) {
				ssize_t m;
				do {
					if (off_out) m = pwrite(fd_out, buf + written, n - written, *off_out);
					else {
						m = send(fd_out, buf + written, n - written, 0);
					}
				} while (m < 0 && errno == EINTR);

				if (m < 0) {
					if ((flags & SPLICE_F_NONBLOCK) && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
					return -1;
				}
				written += m;
				if (off_out) *off_out += m;
			}
			if (off_in) *off_in += n;
		}
		total += n;
	}

	return total;
}
