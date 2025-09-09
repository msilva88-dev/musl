#include <stddef.h>

/* Conservative default for pthread stacks; used by __init_tls paths. */
#if INTPTR_MAX == 0x7fffffff
size_t __default_stacksize = 2u<<20;   /* 2 MiB on 32-bit */
#else
size_t __default_stacksize = 8u<<20;   /* 8 MiB on 64-bit */
#endif
