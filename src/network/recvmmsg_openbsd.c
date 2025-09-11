/* OpenBSD Stage-1: recvmmsg(2) is not available.  Provide a stub so
 * the static libc bootstrap can complete. */
#include <sys/socket.h>
#include <time.h>
#include <errno.h>

int recvmmsg(int fd, struct mmsghdr *msgvec, unsigned int vlen,
             int flags, struct timespec *timeout)
{
	(void)fd; (void)msgvec; (void)vlen; (void)flags; (void)timeout;
	errno = ENOSYS;
	return -1;
}
