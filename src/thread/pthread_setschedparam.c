#include "pthread_impl.h"
#include "lock.h"

int pthread_setschedparam(pthread_t t, int policy, const struct sched_param *param)
{
	int r;
	sigset_t set;
	__block_app_sigs(&set);
	LOCK(t->killlock);
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	switch (policy) {
	case SCHED_FIFO:
	case SCHED_OTHER:
	case SCHED_RR:
		r = !t->tid ? ESRCH : 0;
		t->attr._a_policy = policy;
		if (param) {
			if (param->sched_priority <= PTHREAD_MAX_PRIORITY && param->sched_priority >= PTHREAD_MIN_PRIORITY)
				t->attr._a_prio = param->sched_priority;
			else r = EINVAL;
		}
		break;
	default:
		r = EINVAL;
		break;
	}
#elif defined(__linux__)
	r = !t->tid ? ESRCH : -__syscall(SYS_sched_setscheduler, t->tid, policy, param);
#endif
	UNLOCK(t->killlock);
	__restore_sigs(&set);
	return r;
}
