#ifndef _PTHREAD_ARCH_H
#define _PTHREAD_ARCH_H

/* Minimal __pthread_self for TLS-backed errno.
 * OpenBSD uses %fs for the TCB on amd64.
 */
static inline struct pthread *__pthread_self(void)
{
	struct pthread *self;
	__asm__ __volatile__("mov %%fs:0,%0" : "=r"(self));
	return self;
}

/* TLS layout: TCB at TP. */
#define TLS_ABOVE_TP
#define TP_OFFSET 0
#define DTP_OFFSET 0

#endif
