#define ALIGNBYTES (sizeof(long) - 1)
#define ALIGN(p) (((unsigned long)(p) + ALIGNBYTES) & ~ALIGNBYTES)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define PAGE_MASK (PAGE_SIZE - 1)
#endif
