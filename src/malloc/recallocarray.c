#define _BSD_SOURCE
#include <errno.h>
#include <stdlib.h>
#include <string.h>

void *recallocarray(void *ptr, size_t oldnmemb, size_t nmemb, size_t size)
{
	size_t oldsize = ptr ? oldnmemb * size : 0, newsize;
	if (nmemb && size > SIZE_MAX / nmemb) {
		errno = EINVAL;
		return NULL;
	}
	newsize = nmemb * size;
	if (ptr && oldnmemb && size > SIZE_MAX / oldnmemb) {
		errno = EINVAL;
		return NULL;
	}
	void *p = reallocarray(ptr, nmemb, size);
	if (!p) return NULL;
	if (newsize > oldsize) explicit_bzero((unsigned char *)p + oldsize, newsize - oldsize);
	else if (oldsize > newsize) explicit_bzero((unsigned char *)p + newsize, oldsize - newsize);
	return p;
}
