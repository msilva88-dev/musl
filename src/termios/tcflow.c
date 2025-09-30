#include <termios.h>
#include <sys/ioctl.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <errno.h>
#include <unistd.h>
#endif

int tcflow(int fd, int action)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct termios term;
	unsigned char c;
	int r = -1;

	switch (action) {
        case TCIOFF:
        case TCION:
		if (!tcgetattr(fd, &term)) {
			c = term.c_cc[action == TCION ? VSTART : VSTOP];
			r = write(fd, &c, sizeof(c));
			if (!r || c == _POSIX_VDISABLE) return 0;
		}

		return -1;
	case TCOOFF:
        case TCOON:
		return (ioctl(fd, action == TCOON ? TIOCSTART : TIOCSTOP, 0));
        default:
                errno = EINVAL;
                return -1;
        }
#elif defined(__linux__)
	return ioctl(fd, TCXONC, action);
#endif
}
