#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include "conceal.h"

void free(void *p)
{
	if (!p) return;
	struct conceal_hdr *h = conceal_hdr_from_user(p);
	if (h && h->magic == CONCEAL_MAGIC) {
		size_t user_len = h->len;
		size_t total = sizeof(struct conceal_hdr) + user_len;
		explicit_bzero(p, user_len);

		/* Defensive: only munmap if header seems page-aligned */
		long page_size = sysconf(_SC_PAGESIZE);
		if (page_size > 0 && ((uintptr_t)h % (size_t)page_size) == 0) {
			size_t mlen = pagesize_round(total);
			if (h->flags & CONCEAL_FLAG_MLOCKED) munlock((void *)h, mlen);
			explicit_bzero(h, sizeof(*h));
			munmap((void *)h, mlen);
			return;
		}
	}

	__libc_free(p);
}
