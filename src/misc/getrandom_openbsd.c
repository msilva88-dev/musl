#include <sys/types.h>
#include <errno.h>
#include <stddef.h>
#include <bits/syscall.h>  /* OpenBSD syscall numbers */
#ifdef SYS_getentropy

#ifdef MUSL_OBSD

/* Use the raw syscall to avoid needing any external libc symbol. */
extern long __syscall2(long, long, long);

/* OpenBSD getentropy(2) limits reads to 256 bytes per call. */
#if defined(SYS_getentropy)
ssize_t getrandom(void *buf, size_t buflen, unsigned flags)
{
	(void)flags; /* TODO: honor NONBLOCK/RANDOM if needed */
	unsigned char *p = (unsigned char *)buf;
	size_t n = buflen, total = 0;
	while (n) {
		size_t chunk = n > 256 ? 256 : n;
		long r = __syscall2(SYS_getentropy, (long)p, (long)chunk);
		if (r < 0) {
			if (total) break; /* short read allowed */
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
/* Stage-1 fallback: if we don't have the syscall number yet, return ENOSYS.
 * This keeps the build going; later we will supply OpenBSD syscall numbers.
 */
ssize_t getrandom(void *buf, size_t buflen, unsigned flags)
{
	(void)buf;
	(void)buflen;
	(void)flags;
	errno = ENOSYS;
	return -1;
}
#endif

#endif /* MUSL_OBSD */
