#define _BSD_SOURCE
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include "mallocopts.h"
#include "mchunk.h"

void *malloc_conceal(size_t n)
{
	return malloc_chunk(n, MCHUNK_FLAG_CONCEAL);
}

void *calloc_conceal(size_t m, size_t n)
{
	if (m && n > SIZE_MAX / m) {
		errno = ENOMEM;
		return NULL;
	}
	size_t t = m * n;
	void *p = malloc_chunk(t, MCHUNK_FLAG_CONCEAL);
	if (!p) return NULL;
	explicit_bzero(p, t);
	return p;
}
