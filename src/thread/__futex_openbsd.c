#include <errno.h>
#include <time.h>
#include <sys/syscall.h>
#include <bits/syscall.h>

/* Minimal futex shim using _umtx_op WAIT/WAKE. */

#ifndef SYS__umtx_op
#define SYS__umtx_op  393   /* OpenBSD 7.x */
#endif

#define UMTX_OP_WAIT  2
#define UMTX_OP_WAKE  3

long __syscall(long, ...);

int __futex(volatile int *uaddr, int op, int val,
            const struct timespec *to, int *uaddr2, int val3)
{
	(void)uaddr2; (void)val3;
	switch (op) {
	case 0: { /* FUTEX_WAIT */
		long r = __syscall(SYS__umtx_op, (void*)uaddr, UMTX_OP_WAIT, val, to, 0);
		if (r < 0) { errno = -r; return -1; }
		return 0;
	}
	case 1: { /* FUTEX_WAKE */
		long r = __syscall(SYS__umtx_op, (void*)uaddr, UMTX_OP_WAKE, val, 0, 0);
		if (r < 0) { errno = -r; return -1; }
		return (int)r; /* number woken */
	}
	default:
		errno = ENOSYS;
		return -1;
	}
}
