/* OpenBSD Stage-1: portable __sched_cpucount() with no syscalls and
 * no dependency on cpu_set_t/CPU_* macros. */
#include <stddef.h>
#include <stdint.h>

/* Treat the mask as an opaque byte array. */
int __sched_cpucount(size_t setsize, const void *set)
{
	int n = 0;
	const unsigned char *p = (const unsigned char *)set;
	for (size_t i = 0; i < setsize; i++) {
		unsigned char x = p[i];
		/* count bits in x (portable, branchless) */
		x = (x & 0x55) + ((x >> 1) & 0x55);
		x = (x & 0x33) + ((x >> 2) & 0x33);
		n += (x & 0x0f) + (x >> 4);
	}
	return n;
}

/* Keep symbol local unless musl expects it exported; this matches the
 * original file’s visibility (used by CPU_COUNT_S macro helpers). */
#ifdef __GNUC__
__attribute__((visibility("hidden")))
int __sched_cpucount(size_t setsize, const void *set);
#endif
