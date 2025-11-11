#define _BSD_SOURCE
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>
#include "conceal.h"

void *malloc_conceal(size_t size)
{
	if (size == 0) size = 1;
	if (size > SIZE_MAX - sizeof(struct conceal_hdr)) errno = ENOMEM, return NULL;
	size_t total = sizeof(struct conceal_hdr) + size;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	void *map = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_CONCEAL, -1, 0);
	if (map == MAP_FAILED) return NULL;
#elif defined(__linux__)
	size_t mlen = pagesize_round(total);
	void *map = mmap(NULL, mlen, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
	if (map == MAP_FAILED) return NULL;
	int ml = mlock(map, mlen);
	madvise(map, mlen, MADV_DONTDUMP);
#endif
	struct conceal_hdr *h = (struct conceal_hdr *)map;
	h->magic = CONCEAL_MAGIC;
	h->len = size;
	h->flags = CONCEAL_FLAG_MMAPPED;
#if defined(__linux__)
	if (!ml) h->flags |= CONCEAL_FLAG_MLOCKED;
#endif
	return (void *)(h + 1);
}

void *calloc_conceal(size_t nmemb, size_t size)
{
	if (nmemb && size > SIZE_MAX / nmemb) errno = ENOMEM, return NULL;
	size_t total = nmemb * size;
	void *p = malloc_conceal(total);
	if (!p) return NULL;
	explicit_bzero(p, total);
	return p;
}
