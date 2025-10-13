#define _GNU_SOURCE
#include <fcntl.h>

int fallocate(int fd, off_t base, off_t len)
{
	return posix_fallocate(fd, base, len);
}
