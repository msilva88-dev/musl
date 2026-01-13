#ifndef _MALLOCOPTS_H
#define _MALLOCOPTS_H

hidden extern char *malloc_options;

hidden void free_chunk(void *);
hidden void *malloc_chunk(size_t, int);
hidden void *realloc_chunk(void *, size_t, int);
hidden void *aligned_alloc_chunk(size_t, size_t, int);

hidden void __malloc_donate(char *, char *);
hidden int __malloc_allzerop(void *);

#endif
