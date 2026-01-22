#define _BSD_SOURCE
#include <termios.h>
#include <sys/ioctl.h>
#include <errno.h>

int tcsetattr(int fd, int act, const struct termios *tio)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct termios ltio;
	if (act & TCSASOFT) {
		ltio = *tio;
		ltio.c_cflag |= CIGNORE;
		tio = &ltio;
		act &= ~TCSASOFT;
	}
#endif
	if (act < 0 || act > 2) {
		errno = EINVAL;
		return -1;
	}
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return ioctl(fd, TIOCSETA+act, tio);
#elif defined(__linux__)
	return ioctl(fd, TCSETS+act, tio);
#endif
}
