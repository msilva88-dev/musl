#include <errno.h>

/* musl prototype uses varargs to carry ptid/tls/ctid when present. */
int __clone(int (*fn)(void *), void *stack, int flags, void *arg, ...)
{
	(void)fn; (void)stack; (void)flags; (void)arg;
	errno = ENOSYS;
	return -1;
}
