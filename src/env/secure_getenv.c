#define _GNU_SOURCE
#include <stdlib.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include "libc.h"
#endif

char *secure_getenv(const char *name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __syscall(SYS_issetugid) ? NULL : getenv(name);
#elif defined(__linux__)
	return libc.secure ? NULL : getenv(name);
#endif
}
