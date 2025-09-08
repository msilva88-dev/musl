/* OpenBSD Stage-1: no timer_settime syscall — return ENOSYS. */
#include <time.h>
#include <errno.h>

int timer_settime(timer_t t, int flags,
                  const struct itimerspec *val,
                  struct itimerspec *oldval)
{
	(void)t; (void)flags; (void)val; (void)oldval;
	errno = ENOSYS;
	return -1;
}
