#include <sched.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <errno.h>
#include "pthread_impl.h"
#elif defined(__linux__)
#include "syscall.h"
#endif

int sched_get_priority_max(int policy)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	switch (policy) {
	case SCHED_FIFO:
	case SCHED_OTHER:
	case SCHED_RR:
		return PTHREAD_MAX_PRIORITY;
	default:
		errno = EINVAL;
		return -1;
	}
#elif defined(__linux__)
	return syscall(SYS_sched_get_priority_max, policy);
#endif
}

int sched_get_priority_min(int policy)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	switch (policy) {
	case SCHED_FIFO:
	case SCHED_OTHER:
	case SCHED_RR:
		return PTHREAD_MIN_PRIORITY;
	default:
		errno = EINVAL;
		return -1;
	}
#elif defined(__linux__)
	return syscall(SYS_sched_get_priority_min, policy);
#endif
}
