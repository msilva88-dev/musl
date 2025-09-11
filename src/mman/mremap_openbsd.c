/* OpenBSD Stage-1: mremap() is not available.  Provide a stub so the
 * static libc bootstrap can complete without Linux SYS_mremap. */
#include <sys/mman.h>
#include <errno.h>
#include <stdarg.h>
#include <stddef.h>

void *mremap(void *old_addr, size_t old_len, size_t new_len, int flags, ...)
{
	(void)old_addr; (void)old_len; (void)new_len; (void)flags;
	/* Linux mremap may take an optional new address; swallow varargs. */
	va_list ap; va_start(ap, flags); (void)va_arg(ap, void *); va_end(ap);
	errno = ENOSYS;
	return MAP_FAILED;
}
