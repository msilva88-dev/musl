#define _GNU_SOURCE
#include <stdlib.h>
#include <sys/mman.h>
#include <string.h>
#include "meta.h"
#include "mallocopts.h"

void *realloc(void *p, size_t n)
{
	if (!p) return malloc(n);
	if (size_overflows(n)) return 0;

	struct meta *g = get_meta(p);
	int idx = get_slot_index(p);
	size_t stride = get_stride(g);
	unsigned char *start = g->mem->storage + stride*idx;
	unsigned char *end = start + stride - IB;
	size_t old_size = get_nominal_size(p, end);
	size_t avail_size = end-(unsigned char *)p;
	void *new;

	// only resize in-place if size class matches
	if (n <= avail_size && n<MMAP_THRESHOLD
	    && size_to_class(n)+1 >= g->sizeclass) {
		set_size(p, end, n);
		return p;
	}

	// use mremap if old and new size are both mmap-worthy
	if (g->sizeclass>=48 && n>=MMAP_THRESHOLD) {
		assert(g->sizeclass==63);
		size_t base = (unsigned char *)p-start;
		size_t needed = (n + base + UNIT + IB + 4095) & -4096;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		size_t old_size_pages = g->maplen * 4096UL;

		if (needed <= old_size_pages) {
			size_t newpages = (needed+4095) & ~4095UL;
			if (newpages < old_size_pages) {
				munmap(g->mem + newpages, old_size_pages - newpages);
			}
			new = g->mem;
		} else {
			char *adj = mmap(
				g->mem + old_size_pages,
				needed - old_size_pages,
				PROT_READ | PROT_WRITE,
				MAP_ANON | MAP_PRIVATE,
				-1,
				0
			);

			if (adj != MAP_FAILED && adj == g->mem+old_size_pages) {
				new = g->mem;
			} else {
				new = mmap(
					NULL,
					needed,
					PROT_READ | PROT_WRITE,
					MAP_ANON | MAP_PRIVATE,
					-1,
					0
				);
				if (new != MAP_FAILED) {
					memcpy(new, g->mem, old_size_pages);
					munmap(g->mem, old_size_pages);
				}
			}
		}
#elif defined(__linux__)
		new = g->maplen*4096UL == needed ? g->mem :
			mremap(g->mem, g->maplen*4096UL, needed, MREMAP_MAYMOVE);
#endif
		if (new!=MAP_FAILED) {
			g->mem = new;
			g->maplen = needed/4096;
			p = g->mem->storage + base;
			end = g->mem->storage + (needed - UNIT) - IB;
			*end = 0;
			set_size(p, end, n);
			return p;
		}
	}

	new = malloc(n);
	if (!new) return 0;
	memcpy(new, p, n < old_size ? n : old_size);
	free(p);
	return new;
}
