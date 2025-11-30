#ifndef _MALLOCOPTS_H
#define _MALLOCOPTS_H

#include "atomic.h"
#include "mchunk.h"

hidden extern struct __mallocopts __mallocopts;
hidden void check_malloc_options_once(void);
hidden void free_chunk(void *);
hidden void *malloc_chunk(size_t, int);
hidden void *realloc_chunk(void *, size_t, int);

#endif
