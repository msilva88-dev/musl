#define _BSD_SOURCE
#include <string.h>
#include <strings.h>

int timingsafe_bcmp(const void *s1, const void *s2, size_t n)
{
	return timingsafe_memcmp(s1, s2, n) != 0;
}
