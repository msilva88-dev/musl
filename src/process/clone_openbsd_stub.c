#include <errno.h>
#include <stdarg.h>

/* musl prototype uses varargs to carry ptid/tls/ctid when present. */
int __clone(int (*fn)(void *), void *stack, int flags, void *arg, ...)
{
	(void)fn; (void)stack; (void)flags; (void)arg;
	/* swallow optional variadic arguments (ptid, tls, ctid) */
	va_list ap; va_start(ap, arg);
	while (va_arg(ap, void*)) { /* ignore */ break; }
	va_end(ap);
	errno = ENOSYS;
	return -1;
}
