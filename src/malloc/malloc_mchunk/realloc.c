#include <stdlib.h>
#include "mallocopts.h"
#include "mchunk.h"

void *realloc(void *p, size_t n)
{
	return realloc_chunk(p, n, MCHUNK_FLAG_NONE);
}
