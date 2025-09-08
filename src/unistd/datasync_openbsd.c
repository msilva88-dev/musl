/* OpenBSD Stage-1: implement fdatasync() using fsync(2).
 * This is slightly stronger than required, but correct and portable.
 */
#include <unistd.h>

int fdatasync(int fd)
{
	return fsync(fd);
}
