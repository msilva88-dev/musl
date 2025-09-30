#include <termios.h>
#include <sys/ioctl.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <time.h>
#endif

int tcsendbreak(int fd, int dur)
{
	/* nonzero duration is implementation-defined, so ignore it */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct timespec sleep = { .tv_sec = 0, .tv_nsec = 0x17d78400 };
	int r = ioctl(fd, TIOCSBRK, 0);

	if (!r) {
		nanosleep(&sleep, NULL);
		r = ioctl(fd, TIOCCBRK, 0);
	}

	return r;
#elif defined(__linux__)
	return ioctl(fd, TCSBRK, 0);
#endif
}
