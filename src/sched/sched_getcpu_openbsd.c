/* OpenBSD Stage-1: no getcpu(2).  Return ENOSYS to indicate
 * unavailability to callers that probe for this functionality. */
#include <errno.h>

int sched_getcpu(void)
{
	errno = ENOSYS;
	return -1;
}
