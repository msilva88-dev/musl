#include <errno.h>
#include <stdint.h>
#include <sys/syscall.h>
#include <bits/syscall.h>

/* OpenBSD/amd64 sets FSBASE via: sysarch(AMD64_SET_FSBASE, <void *base>) */

#ifndef SYS_sysarch
#define SYS_sysarch 165   /* from <sys/syscall.h> */
#endif

/* <machine/sysarch.h> value; kept local to avoid global -isystem includes */
#ifndef AMD64_SET_FSBASE
#define AMD64_SET_FSBASE 129
#endif

long __syscall(long, ...); /* provided by musl's syscall glue */

int __set_thread_area(void *p)
{
	/* Pass the TLS base value directly as the 2nd argument. */
	long r = __syscall(SYS_sysarch, AMD64_SET_FSBASE, p);
	if (r < 0) {
		errno = -r;
		return -1;
	}
	return 0;
}
