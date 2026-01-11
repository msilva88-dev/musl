#ifndef _INTERNAL_FUTEX_H
#define _INTERNAL_FUTEX_H

#if defined(__HyperbolaBSD__) ||  defined(__OpenBSD__)
#define FUTEX_WAIT		1
#define FUTEX_WAKE		2
#elif defined(__linux__)
#define FUTEX_WAIT		0
#define FUTEX_WAKE		1
#define FUTEX_FD		2
#endif

#define FUTEX_REQUEUE		3

#if defined(__linux__)
#define FUTEX_CMP_REQUEUE	4
#define FUTEX_WAKE_OP		5
#define FUTEX_LOCK_PI		6
#define FUTEX_UNLOCK_PI		7
#define FUTEX_TRYLOCK_PI	8
#define FUTEX_WAIT_BITSET	9
#endif

#define FUTEX_PRIVATE 128

#if defined(__linux__)
#define FUTEX_CLOCK_REALTIME 256
#endif

#endif
