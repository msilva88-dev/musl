#include <sys/time.h>
#include "fcntl.h"
#include "syscall.h"

int utimes(const char *path, const struct timeval times[2])
{
	return syscall(SYS_utimes, path, times);
}
