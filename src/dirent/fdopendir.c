#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdlib.h>
#include "__dirent.h"

DIR *fdopendir(int fd)
{
	DIR *dir;
	struct stat st;
	int flags = fcntl(fd, F_GETFL);

	if (fstat(fd, &st) < 0 || flags == -1) {
		return 0;
	}
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (
		(flags & O_ACCMODE) != O_RDONLY
		&& (flags & O_ACCMODE) != O_RDWR
	) {
#elif defined(__linux__)
	if (flags & O_PATH) {
#endif
		errno = EBADF;
		return 0;
	}
	if (!S_ISDIR(st.st_mode)) {
		errno = ENOTDIR;
		return 0;
	}
	if (!(dir = calloc(1, sizeof *dir))) {
		return 0;
	}

	fcntl(fd, F_SETFD, FD_CLOEXEC);
	dir->fd = fd;
	return dir;
}
