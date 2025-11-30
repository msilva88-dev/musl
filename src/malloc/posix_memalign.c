#include <stdlib.h>
#include <errno.h>

int posix_memalign(void **res, size_t align, size_t len)
{
	if (!res || (align < sizeof(void*)) || (align & (align-1))) return EINVAL;
	//if (align < sizeof(void *)) return EINVAL;
	void *mem = aligned_alloc(align, len);
	if (!mem) return errno;
	*res = mem;
	return 0;
}
