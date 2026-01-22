#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#endif
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <pty.h>
#include <stdio.h>
#include <pthread.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/types.h>
#include <string.h>
#include <hyperbk/tty.h>
#endif

/* Nonstandard, but vastly superior to the standard functions */

int openpty(int *pm, int *ps, char *name, const struct termios *tio, const struct winsize *ws)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct ptmget ptm;
	int m, s, cs;
#elif defined(__linux__)
	int m, s, n=0, cs;
#endif
	char buf[20];

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	m = open("/dev/ptm", O_RDWR|O_NOCTTY);
#elif defined(__linux__)
	m = open("/dev/ptmx", O_RDWR|O_NOCTTY);
#endif
	if (m < 0) return -1;

	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (ioctl(m, PTMGET, &ptm) < 0)
#elif defined(__linux__)
	if (ioctl(m, TIOCSPTLCK, &n) || ioctl (m, TIOCGPTN, &n))
#endif
		goto fail;

	if (!name) name = buf;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	strlcpy(name, ptm.sn, sizeof(ptm.sn));
	s = ptm.cfd;
	close(ptm.sfd);
#elif defined(__linux__)
	snprintf(name, sizeof buf, "/dev/pts/%d", n);
	if ((s = open(name, O_RDWR|O_NOCTTY)) < 0)
		goto fail;
#endif

	if (tio) tcsetattr(s, TCSANOW, tio);
	if (ws) ioctl(s, TIOCSWINSZ, ws);

	*pm = m;
	*ps = s;

	pthread_setcancelstate(cs, 0);
	return 0;
fail:
	close(m);
	pthread_setcancelstate(cs, 0);
	return -1;
}
