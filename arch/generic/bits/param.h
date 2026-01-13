#define ALIGNBYTES (sizeof(long) - 1)
#define ALIGN(p) (((unsigned long)(p) + ALIGNBYTES) & ~ALIGNBYTES)
