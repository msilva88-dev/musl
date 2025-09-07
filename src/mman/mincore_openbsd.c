/* OpenBSD Stage-1: stub mincore().  The Linux generic version calls
 * SYS_mincore which does not exist here.  A real implementation can
 * be added later; this stub keeps the static libc bootstrap moving. */
#include <sys/types.h>
#include <errno.h>
#include <stddef.h>

int mincore(void *addr, size_t len, unsigned char *vec)
{
	(void)addr;
	(void)len;
	(void)vec;
	errno = ENOSYS;
	return -1;
}
