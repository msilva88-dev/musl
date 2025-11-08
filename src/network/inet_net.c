#define _BSD_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <errno.h>

/* Internal helper: apply prefix mask (IPv4 / IPv6) */
static void apply_mask(void *addr, int af, int bits)
{
	if (af == AF_INET) {
		uint32_t mask = bits == 0 ? 0 : htonl(0xffffffffu << (32 - bits));
		uint32_t *p = (uint32_t *)addr;
		*p &= mask;
	} else if (af == AF_INET6) {
		uint8_t *a = (uint8_t *)addr;
		int full_bytes = bits / 8, rem_bits = bits % 8;

		for (int i = 0; i < 16; i++) {
			if (i < full_bytes) continue;
			else if (i == full_bytes) a[i] &= rem_bits ? (0xFF << (8 - rem_bits)) : 0x00;
			else a[i] = 0;
		}
	}
}

/*
 * inet_net_pton():
 * Parse "192.168.1.0/24" or "2001:db8::/48"
 * into binary address and apply network mask.
 *
 * Returns prefix length (bits) or -1 on error.
 */
int inet_net_pton(int af, const char *src, void *dst, size_t size)
{
	if (!src || !dst) errno = EINVAL, return -1;

	char buf[128];
	strncpy(buf, src, sizeof(buf));
	buf[sizeof(buf) - 1] = '\0';

	char *slash = strchr(buf, '/');
	int bits = (af == AF_INET) ? 32 : (af == AF_INET6) ? 128 : -1;

	if (bits == -1) errno = EAFNOSUPPORT, return -1;

	if (slash) {
		*slash = '\0';
		char *endp;
		long val = strtol(slash + 1, &endp, 10);
		if (*endp != '\0' || val < 0 || (af == AF_INET && val > 32) || (af == AF_INET6 && val > 128)) {
			errno = EINVAL;
			return -1;
		}
		bits = (int)val;
	}

	if (inet_pton(af, buf, dst) != 1) errno = EINVAL, return -1;

	size_t need = (af == AF_INET) ? sizeof(struct in_addr) : sizeof(struct in6_addr);
	if (size < need) errno = ENOSPC, return -1;

	/* Apply network mask (like BSD does) */
	apply_mask(dst, af, bits);
	return bits;
}

/*
 * inet_net_ntop():
 * Convert binary network and prefix length into CIDR string.
 * Example: "192.168.0.0/24" or "2001:db8::/48"
 */
char *inet_net_ntop(int af, const void *src, int bits, char *dst, size_t size)
{
	if (!src || !dst) errno = EINVAL, return NULL;

	char addrbuf[INET6_ADDRSTRLEN];

	if (af != AF_INET && af != AF_INET6) errno = EAFNOSUPPORT, return NULL;
	if (!inet_ntop(af, src, addrbuf, sizeof(addrbuf))) return NULL;

	int maxbits = (af == AF_INET) ? 32 : 128;
	if (bits < 0 || bits > maxbits) errno = EINVAL, return NULL;

	int n = snprintf(dst, size, "%s/%d", addrbuf, bits);
	if (n < 0 || (size_t)n >= size) errno = ENOSPC, return NULL;

	return dst;
}
