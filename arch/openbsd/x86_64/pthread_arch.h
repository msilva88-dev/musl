#ifndef _PTHREAD_ARCH_H
#define _PTHREAD_ARCH_H

/* OpenBSD/amd64: thread pointer (TP) is in %fs, TCB at TP. */
#include <stdint.h>

static inline uintptr_t __get_tp(void)
{
	uintptr_t tp;
	__asm__ __volatile__("mov %%fs:0,%0" : "=r"(tp));
	return tp;
}

/* Prefer a macro so pthread_impl.h will NOT synthesize its fallback.
 * pthread_impl.h checks for a macro named __pthread_self, not a function.
 */
#define __pthread_self() ((pthread_t)__get_tp())

/* TLS layout: TCB at TP. */
#define TLS_ABOVE_TP
#define TP_OFFSET 0
#define DTP_OFFSET 0

/* No gap reserved above TP in musl's x86_64 model. */
#ifndef GAP_ABOVE_TP
#define GAP_ABOVE_TP 0
#endif

#endif
