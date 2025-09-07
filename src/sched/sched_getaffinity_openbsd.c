/* OpenBSD Stage-1: no CPU affinity; provide ENOSYS stub. */
#include <sys/types.h>  /* pid_t */
#include <stddef.h>     /* size_t */
#include <errno.h>

int sched_getaffinity(pid_t tid, size_t cpusetsize, void *mask)
{
	(void)tid; (void)cpusetsize; (void)mask;
	errno = ENOSYS;
	return -1;
}
