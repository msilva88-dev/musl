#ifndef _MALLOCOPTS_H
#define _MALLOCOPTS_H

hidden int check_xmalloc(void *, const char *);
hidden void free_chunk(void *);
hidden void *malloc_chunk(size_t, int);
hidden void *realloc_chunk(void *, size_t, int);

#endif
