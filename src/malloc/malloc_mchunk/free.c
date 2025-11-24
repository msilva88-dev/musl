#include <stdlib.h>
#include "mallocopts.h"

void free(void *p)
{
	free_chunk(p);
}
