#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include "conceal.h"

void free(void *p)
{
	if (!p) return;

	// try to see if this pointer is a 'conceal' allocation
	struct conceal_hdr *h = conceal_hdr_from_user(p);

	// if it's a conceal allocation, wipe and unmap (if page-aligned)
	if (h && h->magic == CONCEAL_MAGIC) {
		// compute user length safely
		size_t user_len = h->len;

		explicit_bzero(p, user_len);

		// defensive: only munmap if header seems page-aligned
		if (!((uintptr_t)h % (size_t)PAGE_SIZE)) {
			size_t total = sizeof(struct conceal_hdr) + user_len;
			size_t mlen = pagesize_round(total);
			if (h->flags & CONCEAL_FLAG_MLOCKED) munlock((void *)h, mlen);
			explicit_bzero(h, sizeof(*h));
			munmap((void *)h, mlen);
			return;
		}

		// If not page-aligned, fall through to regular free as a fallback
	}

	__libc_free(p);
}
