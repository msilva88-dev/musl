#include <stdlib.h>
#include "mallocopts.h"

void *aligned_alloc(size_t align, size_t len)
{
	return aligned_alloc_chunk(align, len, MCHUNK_FLAG_NONE);
}
