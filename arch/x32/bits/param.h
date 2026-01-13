#define ALIGNBYTES (sizeof(long long) - 1)
#define ALIGN(p) (((unsigned long long)(p) + ALIGNBYTES) & ~ALIGNBYTES)
