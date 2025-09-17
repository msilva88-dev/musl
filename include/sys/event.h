#ifndef	_SYS_EPOLL_H
#define	_SYS_EPOLL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <bits/alltypes.h>

struct kevent {
	uintptr_t ident;
	short filter;
	unsigned short flags;
	unsigned int fflags;
	int64_t data;
	void *udata;
};

static inline void EV_SET(
	struct kevent *kevp,
	uintptr_t ident,
	short filter,
	unsigned short flags,
	unsigned int fflags,
	int64_t data,
	void *udata
)
{
    kevp->ident = ident;
    kevp->filter = filter;
    kevp->flags = flags;
    kevp->fflags = fflags;
    kevp->data = data;
    kevp->udata = udata;
}

enum kevent_actions {
	EV_ADD     = 0x1,
	EV_DELETE  = 0x2,
	EV_ENABLE  = 0x4,
	EV_DISABLE = 0x8
};

enum kevent_flags {
	EV_ONESHOT  = 0x0010,
	EV_CLEAR    = 0x0020,
	EV_RECEIPT  = 0x0040,
	EV_DISPATCH = 0x0080,
	EV_FLAG1    = 0x2000,
	EV_SYSFLAGS = 0xF000
};

enum kevent_returned {
	EV_ERROR = 0x4000,
	EV_EOF   = 0x8000
};

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

#endif /* sys/event.h */
