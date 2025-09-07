/* OpenBSD Stage-1: minimal sched_get_priority_min()
 * See comment in sched_get_priority_max_openbsd.c.
 */
#include <sched.h>
#include <errno.h>

int sched_get_priority_min(int policy)
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
