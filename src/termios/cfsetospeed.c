#define _BSD_SOURCE
#include <termios.h>
#include <sys/ioctl.h>
#include <errno.h>

int cfsetospeed(struct termios *tio, speed_t speed)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	tio->c_ospeed = speed;
#elif defined(__linux__)
	if (speed & ~CBAUD) {
		errno = EINVAL;
		return -1;
	}
	tio->c_cflag &= ~CBAUD;
	tio->c_cflag |= speed;
#endif
	return 0;
}

int cfsetispeed(struct termios *tio, speed_t speed)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	tio->c_ispeed = speed;
#elif defined(__linux__)
	if (speed & ~CBAUD) {
		errno = EINVAL;
		return -1;
	}
	tio->c_cflag &= ~CIBAUD;
	tio->c_cflag |= speed * (CIBAUD/CBAUD);
#endif
	return 0;
}
