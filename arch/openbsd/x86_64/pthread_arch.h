#ifndef _PTHREAD_ARCH_H
#define _PTHREAD_ARCH_H

/* OpenBSD/amd64 uses %fs for the thread pointer (TCB at TP).
 * Expose __get_tp() so pthread_impl.h’s fallback __pthread_self()
 * macro can compute the current pthread_t without redefining it here.
 */
#include <stdint.h>
static inline uintptr_t __get_tp(void)
{
	uintptr_t tp;
	__asm__ __volatile__("mov %%fs:0,%0" : "=r"(tp));
	return tp;
}

/* TLS layout: TCB at TP. */
#define TLS_ABOVE_TP
#define TP_OFFSET 0
#define DTP_OFFSET 0

#endif
