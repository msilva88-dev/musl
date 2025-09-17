#ifndef	_SYS_EPOLL_H
#define	_SYS_EPOLL_H

#ifdef __cplusplus
extern "C" {
#endif

int kqueue(void);
int kevent(
	int,
	const struct kevent *,
	int,
	struct kevent *,
	int,
	const struct timespec *
);
#if defined(__HyperbolaBSD__)
int kqueue_create(void);
int kqueue_ctl(int, struct kevent *, int);
int kqueue_wait(int, struct kevent *, int, const struct timespec *);
#endif

#ifdef __cplusplus
}
#endif

#endif /* sys/epoll.h */
