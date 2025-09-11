/* OpenBSD Stage-1: minimal sched_get_priority_max()
 * OpenBSD effectively only supports SCHED_OTHER; no realtime ranges.
 */
#include <sched.h>
#include <errno.h>

int sched_get_priority_max(int policy)
{
	switch (policy) {
	case SCHED_OTHER:
		return 0;
#ifdef SCHED_IDLE
	case SCHED_IDLE:
		return 0;
#endif
	default:
		errno = EINVAL;
		return -1;
	}
}
