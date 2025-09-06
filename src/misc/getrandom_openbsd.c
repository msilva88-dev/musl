#include <sys/types.h>
#include <errno.h>
#include <stddef.h>
#include <bits/syscall.h>   /* OpenBSD syscall numbers via <sys/syscall.h> */
#include "syscall.h"        /* musl internal __syscall() helper */

#ifdef MUSL_OBSD

/* OpenBSD getentropy(2) is limited to 256 bytes per call. */
#if defined(SYS_getentropy)
ssize_t getrandom(void *buf, size_t buflen, unsigned flags)
{
	(void)flags; /* TODO: honor NONBLOCK/RANDOM if meaningful */
	unsigned char *p = (unsigned char *)buf;
	size_t n = buflen, total = 0;
	while (n) {
		size_t chunk = n > 256 ? 256 : n;
		long r = __syscall(SYS_getentropy, (long)p, (long)chunk);
		if (r < 0) {
			if (total) break;      /* short read semantics */
			errno = (int)-r;
			return -1;
		}
		p += chunk;
		n -= chunk;
		total += chunk;
	}
	return (ssize_t)total;
}
#else
/* Stage-1 fallback: compile even if SYS_getentropy isn't visible yet. */
ssize_t getrandom(void *buf, size_t buflen, unsigned flags)
{
	(void)buf; (void)buflen; (void)flags;
	errno = ENOSYS;
	return -1;
}
#endif /* SYS_getentropy */

#endif /* MUSL_OBSD */
