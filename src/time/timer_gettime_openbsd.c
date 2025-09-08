/* OpenBSD Stage-1: no timer_gettime syscall — return ENOSYS. */
#include <time.h>
#include <errno.h>

int timer_gettime(timer_t t, struct itimerspec *val)
{
	(void)t; (void)val;
	errno = ENOSYS;
	return -1;
}
