#include <errno.h>
#include <stdint.h>
#include <sys/syscall.h>
#include <bits/syscall.h>

/* OpenBSD exposes FSBASE set via sysarch(AMD64_SET_FSBASE, p).
 * Avoid relying on system headers globally; use the syscall directly.

#ifndef SYS_sysarch
#define SYS_sysarch 165   /* OpenBSD 7.x */
#endif

#ifndef AMD64_SET_FSBASE
#define AMD64_SET_FSBASE 129  /* <machine/sysarch.h> */
#endif

long __syscall(long, ...); /* internal syscall glue */

int __set_thread_area(void *p)
{
	/* Pass the TLS base value directly as the 2nd argument. */
	long r = __syscall(SYS_sysarch, AMD64_SET_FSBASE, p);
	if (r < 0) { errno = -r; return -1; }
	return 0;
}
