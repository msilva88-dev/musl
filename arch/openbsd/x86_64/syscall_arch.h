#ifndef _MUSL_OBSD_X86_64_SYSCALL_ARCH_H
#define _MUSL_OBSD_X86_64_SYSCALL_ARCH_H

#include <sys/types.h>
#include <sys/syscall.h>

static inline long __syscall0(long n)
{
	long r; char c;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall1(long n, long a1)
{
	long r; char c;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall2(long n, long a1, long a2)
{
	long r; char c;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1), "S"(a2)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall3(long n, long a1, long a2, long a3)
{
	long r; char c;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1), "S"(a2), "d"(a3)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall4(long n, long a1, long a2, long a3, long a4)
{
	long r; char c;
	register long r10 __asm__("r10") = a4;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1), "S"(a2), "d"(a3), "r"(r10)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall5(long n, long a1, long a2, long a3, long a4, long a5)
{
	long r; char c;
	register long r10 __asm__("r10") = a4;
	register long r8  __asm__("r8")  = a5;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1), "S"(a2), "d"(a3), "r"(r10), "r"(r8)
		: "rcx","r11","memory");
	return c ? -r : r;
}

static inline long __syscall6(long n, long a1, long a2, long a3, long a4, long a5, long a6)
{
	long r; char c;
	register long r10 __asm__("r10") = a4;
	register long r8  __asm__("r8")  = a5;
	register long r9  __asm__("r9")  = a6;
	__asm__ volatile ("syscall"
		: "=@ccc"(c), "=a"(r)
		: "a"(n), "D"(a1), "S"(a2), "d"(a3), "r"(r10), "r"(r8), "r"(r9)
		: "rcx","r11","memory");
	return c ? -r : r;
}

#define VDSO_USEFUL 0

#endif
