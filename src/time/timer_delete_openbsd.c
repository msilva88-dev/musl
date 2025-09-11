/* OpenBSD Stage-1: no timer_delete syscall — return ENOSYS. */
#include <time.h>
#include <errno.h>

int timer_delete(timer_t t)
{
	(void)t;
	errno = ENOSYS;
	return -1;
}
