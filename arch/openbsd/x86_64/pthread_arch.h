#ifndef _PTHREAD_ARCH_H
#define _PTHREAD_ARCH_H

/* OpenBSD/amd64 uses %fs as the thread pointer (TP) with the TCB at TP. */

static inline uintptr_t __get_tp(void)
{
	uintptr_t tp;
	__asm__ __volatile__("mov %%fs:0,%0" : "=r"(tp));
	return tp;
}

/* Provide an explicit __pthread_self() to avoid fallback macro paths. */
struct pthread;
static inline struct pthread *__pthread_self(void)
{
	return (struct pthread *)__get_tp();
}

/* TLS layout: TCB at TP. */
#define TLS_ABOVE_TP
#define TP_OFFSET 0
#define DTP_OFFSET 0

#endif
