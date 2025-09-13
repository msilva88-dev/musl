#define _GNU_SOURCE
#include <sys/uio.h>
#include <unistd.h>
#include "syscall.h"

ssize_t pwritev(int fd, const struct iovec *iov, int count, int pad, off_t ofs)
{
	if (ofs==-1) return writev(fd, iov, count);
	return syscall_cp(SYS_pwritev, fd, iov, count, pad
		(long)(ofs), (long)(ofs>>32));
}
