#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

long pathconf(const char *path, int name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __syscall(SYS_pathconf, path, name);
#elif defined(__linux__)
	return fpathconf(-1, name);
#endif
}
