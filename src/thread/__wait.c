#include "pthread_impl.h"

void __wait(volatile int *addr, volatile int *waiters, int val, int priv)
{
	int spins=100;
	if (priv) priv = FUTEX_PRIVATE;
	while (spins-- && (!waiters || !*waiters)) {
		if (*addr==val) a_spin();
		else return;
	}
	if (waiters) a_inc(waiters);
	while (*addr==val) {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		__syscall(SYS_futex,addr,FUTEX_WAIT|priv,val,NULL,NULL) != -ENOSYS
		|| __syscall(SYS_futex, addr, FUTEX_WAIT, val, NULL, NULL);
#elif defined(__linux__)
		__syscall(SYS_futex, addr, FUTEX_WAIT|priv, val, 0) != -ENOSYS
		|| __syscall(SYS_futex, addr, FUTEX_WAIT, val, 0);
#endif
	}
	if (waiters) a_dec(waiters);
}
