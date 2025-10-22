#define _BSD_SOURCE
#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include "libc.h"
#endif

int issetugid(void)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __syscall(SYS_issetugid);
#elif defined(__linux__)
	return libc.secure;
#endif
}
