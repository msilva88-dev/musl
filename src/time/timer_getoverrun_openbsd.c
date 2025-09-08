/* OpenBSD Stage-1: no timer_getoverrun syscall — return ENOSYS. */
#include <time.h>
#include <errno.h>

int timer_getoverrun(timer_t t)
{
	(void)t;
	errno = ENOSYS;
	return -1;
}
