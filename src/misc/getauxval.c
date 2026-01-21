#define __NEED_size_t

#include <bits/alltypes.h>

#include <sys/auxv.h>
#include <errno.h>
#include "libc.h"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

unsigned long __getauxval(unsigned long item)
{
	size_t *auxv = libc.auxv;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (item == AT_SECURE) return __syscall(SYS_issetugid);
#elif defined(__linux__)
	if (item == AT_SECURE) return libc.secure;
#endif
	for (; *auxv; auxv+=2)
		if (*auxv==item) return auxv[1];
	errno = ENOENT;
	return 0;
}

weak_alias(__getauxval, getauxval);
