#define _BSD_SOURCE
#include <stdio.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>

char *inet_neta(in_addr_t src, char *dst, size_t size)
{
	if (!dst || size == 0) errno = EINVAL, return NULL;

	unsigned char a[4];
	int len = 0;

	in_addr_t host = ntohl(src);

	a[0] = (host >> 24) & 0xFF;
	a[1] = (host >> 16) & 0xFF;
	a[2] = (host >> 8)  & 0xFF;
	a[3] = host & 0xFF;

	if (a[3] != 0) len = snprintf(dst, size, "%u.%u.%u.%u", a[0], a[1], a[2], a[3]);
	else if (a[2] != 0) len = snprintf(dst, size, "%u.%u.%u", a[0], a[1], a[2]);
	else if (a[1] != 0) len = snprintf(dst, size, "%u.%u", a[0], a[1]);
	else len = snprintf(dst, size, "%u", a[0]);

	if (len < 0 || (size_t)len >= size) errno = ENOSPC, return NULL;

	return dst;
}
