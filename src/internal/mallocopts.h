#ifndef _MALLOCOPTS_H
#define _MALLOCOPTS_H

#include "atomic.h"
#include "mchunk.h"

// mo_cachesize: 0..8 → 2**n * 1KB (default=64KB)
// mo_mutexes:  0..5 → 2**n threads (default=8)
#define MALLOC_MAX_CACHE 8
#define MALLOC_MAX_MUTEX 5
#define MAX_DELAYED_CHUNKS 64
#define JUNK_PATTERN_ALLOC 0xDB
#define JUNK_PATTERN_FREE 0xDF

hidden extern struct __mallocopts __mallocopts;
hidden extern struct __delayed_chunk __delayed_chunks[];
hidden extern int __delayed_count;
hidden void check_malloc_options_once(void);
hidden void fill_junk(void *, size_t, int);
hidden void freecheck(void *, struct __mchunk *);
hidden void *mguard(size_t, int);
hidden int munguard(void *,size_t);
hidden void *mreguard(void *, size_t, size_t);
hidden void free_chunk(void *);
hidden int free_mchunk(void *);
hidden void *malloc_chunk(size_t, int);
hidden void *realloc_chunk(void *, size_t, int);
hidden void protect_chunk(void *, size_t);
hidden void unprotect_chunk(void *, size_t);
hidden void register_delayed_chunk(void *, size_t);

#endif
