#include <stdlib.h>
#include <errno.h>
#include "mallocopts.h"

int posix_memalign(void **res, size_t align, size_t len)
{
	if (!res || (align < sizeof(void*)) || (align & (align-1))) return EINVAL;
	//if (align < sizeof(void *)) return EINVAL;

	void *mem = aligned_alloc(align, len);
	if (!mem) {
		check_malloc_options_once();
		if (__mallocopts.mo_xmalloc) {
			static const char werr[] = "posix_memalign(): out of memory\n";
			write(2, werr, sizeof(werr) - 1);
			a_crash();
		}
		return errno;
	}
	*res = mem;
	return 0;
}
