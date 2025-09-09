#include <sys/types.h>
#include <sys/mman.h>
#include <errno.h>
#include <stddef.h>

/* mallocng weakly references __mremap; provide ENOSYS stub. */
void *__mremap(void *old, size_t oldsz, size_t newsz, int flags)
{
	(void)old; (void)oldsz; (void)newsz; (void)flags;
	errno = ENOSYS;
	return (void *)-1;
}
