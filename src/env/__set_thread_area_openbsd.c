#include <errno.h>
#include <stdint.h>
#include <sys/syscall.h>
#include <bits/syscall.h>

/* OpenBSD: set FSBASE via sysarch(AMD64_SET_FSBASE, &arg) */

#ifndef SYS_sysarch
#define SYS_sysarch 165   /* OpenBSD 7.x */
#endif

#ifndef AMD64_SET_FSBASE
#define AMD64_SET_FSBASE 129  /* <machine/sysarch.h> */
#endif

struct __obsd_fsbase_arg { void *base; };

long __syscall(long, ...); /* internal syscall glue */

int __set_thread_area(void *p)
{
	struct __obsd_fsbase_arg arg = { .base = p };
	long r = __syscall(SYS_sysarch, AMD64_SET_FSBASE, &arg);
	if (r < 0) { errno = -r; return -1; }
	return 0;
}
