#include <sys/types.h>
#include <sys/mman.h>
#include <errno.h>
#include <stddef.h>
#include <stdarg.h>

/* mallocng weakly references __mremap; provide ENOSYS stub. */
void *__mremap(void *old, size_t oldsz, size_t newsz, int flags, ...)
{
	(void)old; (void)oldsz; (void)newsz; (void)flags;
	/* optional extra arg (newaddr) may be passed; ignore it */
	va_list ap; va_start(ap, flags); (void)va_arg(ap, void *); va_end(ap);
	errno = ENOSYS;
	return (void *)-1;
}
