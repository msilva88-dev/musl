#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include "mallocopts.h"
#include "mchunk.h"

void *malloc(size_t n)
{
	return malloc_chunk(n, MCHUNK_FLAG_NONE);
}

/*
void *calloc(size_t m, size_t n)
{
	if (m && n > SIZE_MAX / m) {
		errno = ENOMEM;
		return NULL;
	}
	size_t t = m * n;
	void *p = malloc_chunk(t, MCHUNK_FLAG_NONE);
	if (!p) return NULL;
	memset(p, 0, t);
	return p;
}
*/
