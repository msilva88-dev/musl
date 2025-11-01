#define _BSD_SOURCE
#include <string.h>

int timingsafe_memcmp(const void *vl, const void *vr, size_t n)
{
	const unsigned char *l=vl, *r=vr;
	int d = 0;
	for (; n; n--, l++, r++) {
		unsigned char x = *l ^ *r;
		d |= ((int)*l - (int)*r) & -((int)(d == 0 && x != 0));
	}
	return d;
}
