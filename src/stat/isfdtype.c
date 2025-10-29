#define _BSD_SOURCE
#include <sys/stat.h>

int isfdtype(int fd, int type)
{
	struct stat statb;
	int rstat = fstat(fd, &statb);
	if (rstat) return -1;
	int rtype = statb.st_mode & S_IFMT;
	int ret = rtype == type;
	return ret;
}
