/* OpenBSD Stage-1: sendmmsg(2) is not available.  Provide a stub. */
#include <sys/socket.h>
#include <errno.h>

int sendmmsg(int fd, struct mmsghdr *msgvec, unsigned int vlen, int flags)
{
	(void)fd; (void)msgvec; (void)vlen; (void)flags;
	errno = ENOSYS;
	return -1;
}
