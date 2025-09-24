#include <unistd.h>
#include <errno.h>

// sendfile_wrapper

ssize_t sendfile(int out_fd, int in_fd, off_t *ofs, size_t count)
{
	char buf[8192];
	ssize_t r, w, total = 0;

	if (ofs) {
		lseek(in_fd, *ofs, SEEK_SET);
	}

	while (count > 0) {
		r = read(in_fd, buf, count < sizeof(buf) ? count : sizeof(buf));

		if (r <= 0) {
			break;
		}

		w = write(out_fd, buf, r);

		if (w != r) {
			return -1;
		}

		total += r;
		count -= r;
	}

	if (ofs) {
		*ofs += total;
	}

	return total;
}
