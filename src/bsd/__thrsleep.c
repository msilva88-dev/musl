#define _BSD_SOURCE
#include <time.h>
#include "syscall.h"

int __thrsleep(
	const volatile void *id,
	clockid_t clock_id,
	const struct timespec *abstime,
	void *lock,
	const int *abort
)
{
	return syscall(SYS___thrsleep, id, clock_id, abstime, lock, abort);
}

int __thrwakeup(const volatile void *id, int count)
{
	return syscall(SYS___thrwakeup, id, count);
}
