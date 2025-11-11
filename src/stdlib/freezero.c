#define _BSD_SOURCE
#include <stdlib.h>
#include <string.h>

void freezero(void *ptr, size_t sz)
{
	if (ptr == NULL) return;
	explicit_bzero(ptr, sz);
	free(ptr);
}
