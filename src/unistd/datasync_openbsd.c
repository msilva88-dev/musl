/* OpenBSD Stage-1:
 * datasync(2) is specified to sync data only; route to fdatasync(2).
 */
#include <unistd.h>

int datasync(int fd)
{
	return fdatasync(fd);
}
