#include <sys/types.h>
#include <sys/event.h>
#include <unistd.h>
#include <errno.h>
#include "syscall.h"

int kevent(
	int fd,
	const struct kevent *changelist,
	int nchanges,
	struct kevent *eventlist,
	int nevents,
	const struct timespec *timeout
)
{
	return syscall(
		SYS_kevent,
		fd,
		changelist,
		nchanges,
		eventlist,
		nevents,
		timeout
	);
}

int kqueue(void)
{
	return syscall(SYS_kqueue);
}

int kqueue_create(void)
{
        return syscall(SYS_kqueue);
}

int kqueue_ctl(int fd, struct kevent *changelist, int nchanges)
{
	return kevent(fd, changelist, nchanges, NULL, 0, NULL);
}

int kqueue_wait(
	int fd,
	struct kevent *eventlist,
	int nevents,
	const struct timespec *timeout
)
{
	return kevent(fd, NULL, 0, eventlist, nevents, timeout);
}
