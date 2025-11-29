#define _BSD_SOURCE
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#ifdef __GNUC__
#define UNUSED_A __attribute__((unused))
#else
#define UNUSED_A
#endif

void lcong48_non_deterministic(unsigned short p[7])
{
	/* Ignore user-supplied state, use strong randomness */
	arc4random_buf(p, sizeof(unsigned short) * 7);
}

unsigned short *seed48_non_deterministic(unsigned short xseed[3] UNUSED_A) {
	(void)xseed; /* ignore */
	/* Ignore xseed, return random seed instead */
	static unsigned short s[3];
	arc4random_buf(s, sizeof(s));
	return s;
}

void srand_non_deterministic(unsigned seed UNUSED_A) {
	(void)seed; /* ignore */
	/* nothing to do; arc4random does not need seeding */
}

void srand48_non_deterministic(long seed UNUSED_A) {
	(void)seed; /* ignore */
	/* nothing to do; arc4random does not need seeding */
}

void srandom_non_deterministic(unsigned int seed UNUSED_A) {
	(void)seed; /* ignore */
	/* nothing to do; arc4random does not need seeding */
}

void srandomdev(void) {
	/* nothing to do; arc4random always non-deterministic */
}
