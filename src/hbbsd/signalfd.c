#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

// signalfd_wrapper

int signalfd(int fd __attribute__((unused)), const sigset_t *sigs, int flags)
{
	(void)fd;
	int kq = kqueue();

	if (kq < 0) {
		return -1;
	}

	struct kevent ev;
	for (int sig = 1; sig < _NSIG; sig++) {
		if (sigismember(sigs, sig)) {
			EV_SET(&ev, sig, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);

			if (kevent(kq, &ev, 1, NULL, 0, NULL) < 0) {
				close(kq);

				return -1;
			}

			sigaddset((sigset_t *)sigs, sig);
		}
	}

	if (flags & SFD_CLOEXEC) {
		fcntl(kq, F_SETFD, FD_CLOEXEC);
	}

	if (flags & SFD_NONBLOCK) {
		fcntl(kq, F_SETFL, O_NONBLOCK);
	}

	return kq;
}
