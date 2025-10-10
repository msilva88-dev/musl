#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include <string.h>
#include <errno.h>
#endif

int getlogin_r(char *name, size_t size)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_getlogin_r, name, size);
#elif defined(__linux__)
	char *logname = getlogin();
	if (!logname) return ENXIO; /* or...? */
	if (strlen(logname) >= size) return ERANGE;
	strcpy(name, logname);
	return 0;
#endif
}
