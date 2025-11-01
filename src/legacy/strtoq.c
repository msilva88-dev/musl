#define _BSD_SOURCE
#include <sys/types.h>
#include "stdio_impl.h"
#include "intscan.h"
#include "shgetc.h"
#include <inttypes.h>
#include <limits.h>
#include <ctype.h>

static unsigned long long strtox(const char *s, char **p, int base, unsigned long long lim)
{
	FILE f;
	sh_fromstring(&f, s);
	shlim(&f, 0);
	unsigned long long y = __intscan(&f, base, 1, lim);
	if (p) {
		size_t cnt = shcnt(&f);
		*p = (char *)s + cnt;
	}
	return y;
}

u_quad_t strtouq(const char *restrict s, char **restrict p, int base)
{
	return (u_quad_t)strtox(s, p, base, ULLONG_MAX);
}

quad_t strtoq(const char *restrict s, char **restrict p, int base)
{
	return (quad_t)strtox(s, p, base, LLONG_MIN);
}
