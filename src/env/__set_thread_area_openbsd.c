#include <errno.h>
#include <stdint.h>
#include <sys/syscall.h>
#include <stddef.h>
#include <bits/syscall.h>

/* OpenBSD/amd64 sets FSBASE via: sysarch(AMD64_SET_FSBASE, <void *base>) */

/* Define constants unconditionally to avoid preprocessor confusion. */
#undef  SYS_sysarch
#define SYS_sysarch 165   /* from <sys/syscall.h> */

/* <machine/sysarch.h> value; keep local to avoid global -isystem includes */
#undef  AMD64_SET_FSBASE
#define AMD64_SET_FSBASE 129

long __syscall(long, ...); /* provided by musl's syscall glue */

int __set_thread_area(void *p)
{
	/* sysarch expects a pointer to the new FS base value. */
	unsigned long base = (unsigned long)p;
	long r = __syscall(SYS_sysarch, AMD64_SET_FSBASE, &base);
	if (r < 0) {
		errno = -r;    /* __syscall returns -errno on failure */
		return -1;
	}
	return 0;
}
