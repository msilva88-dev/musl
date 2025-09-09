#ifndef _PTHREAD_ARCH_H
#define _PTHREAD_ARCH_H

#include <stdint.h>

/* OpenBSD/amd64: %fs:0 holds the pthread self pointer. */
static inline uintptr_t __get_tp(void)
{
	uintptr_t tp;
	__asm__ __volatile__("mov %%fs:0,%0" : "=r"(tp));
	return tp;
}

/* Intentionally do NOT define TLS_ABOVE_TP. We want musl's generic x86_64
 * layout (__pthread_self() == __get_tp()) just like upstream Linux. */

#endif
