#include <termios.h>
#include <sys/ioctl.h>

int tcgetattr(int fd, struct termios *tio)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (ioctl(fd, TIOCGETA, tio))
#elif defined(__linux__)
	if (ioctl(fd, TCGETS, tio))
#endif
		return -1;
	return 0;
}
