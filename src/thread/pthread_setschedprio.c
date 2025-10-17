#include "pthread_impl.h"
#include "lock.h"

int pthread_setschedprio(pthread_t t, int prio)
{
	int r;
	sigset_t set;
	__block_app_sigs(&set);
	LOCK(t->killlock);
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (prio <= PTHREAD_MAX_PRIORITY && prio >= PTHREAD_MIN_PRIORITY) {
		r = !t->tid ? ESRCH : 0;
		t->attr._a_prio = prio;
	} else {
		r = EINVAL;
	}
#elif defined(__linux__)
	r = !t->tid ? ESRCH : -__syscall(SYS_sched_setparam, t->tid, &prio);
#endif
	UNLOCK(t->killlock);
	__restore_sigs(&set);
	return r;
}
