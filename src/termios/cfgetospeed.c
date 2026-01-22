#define _BSD_SOURCE
#include <termios.h>
#include <sys/ioctl.h>

speed_t cfgetospeed(const struct termios *tio)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return tio->c_ospeed;
#elif defined(__linux__)
	return tio->c_cflag & CBAUD;
#endif
}

speed_t cfgetispeed(const struct termios *tio)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return tio->c_ispeed;
#elif defined(__linux__)
	return (tio->c_cflag & CIBAUD) / (CIBAUD/CBAUD);
#endif
}
