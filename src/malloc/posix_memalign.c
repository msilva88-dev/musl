#include <stdlib.h>
#include <errno.h>
#include "mallocopts.h"

int posix_memalign(void **res, size_t align, size_t len)
{
	if (!res || (align < sizeof(void*)) || (align & (align-1))) return EINVAL;
	//if (align < sizeof(void *)) return EINVAL;

	void *mem = aligned_alloc(align, len);
	if (check_xmalloc(mem, "posix_memalign(): allocation failed\n")) return ENOMEM;
	*res = mem;
	return 0;
}
