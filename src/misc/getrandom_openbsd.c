#include <sys/types.h>
#include <sys/syscall.h>
#include <errno.h>
#include <stddef.h>

#ifdef MUSL_OBSD

/* Use the raw syscall to avoid needing any external libc symbol. */
extern long __syscall2(long, long, long);

/* OpenBSD getentropy(2) limits reads to 256 bytes per call. */
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

#endif /* MUSL_OBSD */
