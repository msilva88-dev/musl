#include <termios.h>
#include <sys/ioctl.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <errno.h>
#endif

int tcflush(int fd, int queue)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return ioctl(fd, TIOCFLUSH, queue);
#elif defined(__linux__)
	return ioctl(fd, TCFLSH, queue);
#endif
}
