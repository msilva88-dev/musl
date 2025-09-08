/* OpenBSD Stage-1:
 * Implement fdatasync(2) using fsync(2). Semantics are stronger but safe.
 */
#include <unistd.h>

int fdatasync(int fd)
{
	/* OpenBSD: no dedicated syscall; fsync is the closest. */
	return fsync(fd);
}
