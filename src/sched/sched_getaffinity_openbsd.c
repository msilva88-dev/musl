/* OpenBSD Stage-1: no CPU affinity; provide ENOSYS stub. */
#include <sched.h>
#include <errno.h>

int sched_getaffinity(pid_t tid, size_t cpusetsize, cpu_set_t *mask)
{
	(void)tid; (void)cpusetsize; (void)mask;
	errno = ENOSYS;
	return -1;
}
