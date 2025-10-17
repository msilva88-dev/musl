#include "pthread_impl.h"
#include "lock.h"

int pthread_getschedparam(pthread_t t, int *restrict policy, struct sched_param *restrict param)
{
	int r;
	sigset_t set;
	__block_app_sigs(&set);
	LOCK(t->killlock);
	if (!t->tid) {
		r = ESRCH;
	} else {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		if (policy) {
			*policy = t->attr._a_policy;
			if (param) param->sched_priority = t->attr._a_prio;
			r = 0;
		} else {
			r = EINVAL;
		}
#elif defined(__linux__)
		r = -__syscall(SYS_sched_getparam, t->tid, param);
		if (!r) {
			*policy = __syscall(SYS_sched_getscheduler, t->tid);
		}
#endif
	}
	UNLOCK(t->killlock);
	__restore_sigs(&set);
	return r;
}
