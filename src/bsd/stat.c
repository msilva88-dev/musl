#define _GNU_SOURCE
#include <sys/stat.h>
#include <syscall.h>
#include <errno.h>

int stat(const char *restrict path, struct stat *ub)
{
	int ret = __syscall(SYS_stat, path, ub);
	if (ret != -ENOSYS) return __syscall_ret(ret);
	return 0;
}
