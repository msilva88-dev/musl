#include <stdlib.h>
#include "mallocopts.h"

void __libc_free(void *p)
{
	free_chunk(p);
}
