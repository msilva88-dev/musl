/* OpenBSD Stage-1: no timer_create syscall — return ENOSYS. */
#include <time.h>
#include <errno.h>

int timer_create(clockid_t clk, struct sigevent *evp, timer_t *t)
{
	(void)clk; (void)evp; (void)t;
	errno = ENOSYS;
	return -1;
}
