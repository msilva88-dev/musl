/* OpenBSD Stage-1: no real-time RR interval query syscall.
 * Provide a minimal stub so the static bootstrap completes. */
#include <sys/types.h>   /* pid_t */
#include <time.h>        /* struct timespec */
#include <errno.h>

int sched_rr_get_interval(pid_t pid, struct timespec *ts)
{
	(void)pid;
	(void)ts;
	errno = ENOSYS;
	return -1;
}
