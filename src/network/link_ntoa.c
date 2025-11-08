#define _BSD_SOURCE
#include <stdio.h>
#include <string.h>
#include <net/if_dl.h>
#include <errno.h>

/*
 * link_ntoa_r():
 * Thread-safe version of link_ntoa().
 * Converts AF_LINK address to human-readable form into user buffer.
 *
 * Example:
 *   em0: 00:11:22:33:44:55
 *
 * Returns dst on success, or NULL on error (errno set).
 */
char *link_ntoa_r(const struct sockaddr_dl *sdl, char *dst, size_t size)
{
	if (!sdl || !dst || size == 0) errno = EINVAL, return NULL;

	char tmp[64], *p = tmp;
	unsigned char *addr;
	int n = 0;

	*p = '\0';

	/* Interface name (if present) */
	if (sdl->sdl_nlen > 0 && sdl->sdl_nlen < sizeof(sdl->sdl_data)) {
		memcpy(p, sdl->sdl_data, sdl->sdl_nlen);
		p += sdl->sdl_nlen;
		*p++ = ':';
		*p++ = ' ';
	}

	/* Hardware address */
	addr = LLADDR(sdl);
	for (int i = 0; i < sdl->sdl_alen; i++) {
		n = snprintf(p, sizeof(tmp) - (p - tmp), "%s%02x", i ? ":" : "", addr[i]);
		if (n < 0 || (size_t)n >= sizeof(tmp) - (p - tmp)) errno = ENOSPC, return NULL;
		p += n;
	}

	/* Copy to destination buffer */
	size_t len = p - tmp;
	if ((size_t)len >= size) errno = ENOSPC, return NULL;

	memcpy(dst, tmp, len + 1);
	return dst;
}

/*
 * Non-reentrant version (BSD-compatible).
 * Uses static buffer — not thread-safe.
 */
char *link_ntoa(const struct sockaddr_dl *sdl)
{
	static char buf[64];
	if (!link_ntoa_r(sdl, buf, sizeof(buf))) return NULL;
	return buf;
}
