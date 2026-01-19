/*
 * Copyright (c) 1999,2000,2001 Jonathan Lemon <jlemon@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef _SYS_EVENT_H
#define _SYS_EVENT_H

#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_int64_t
#define __NEED_time_t
#define __NEED_struct_timespec
#define __NEED_uintptr_t

#include <bits/alltypes.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/queue.h>
#elif defined(__OpenBSD__)
#include <sys/queue.h>
#endif

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

struct klistops;
SLIST_HEAD(knlist, knote);

struct klist {
	struct knlist kl_list;
	const struct klistops *kl_ops;
	void *kl_arg;
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
