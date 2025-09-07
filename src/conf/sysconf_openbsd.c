/* Minimal OpenBSD sysconf() for Stage-1 bring-up, no sysctl(3) needed. */
#include <unistd.h>
#include <errno.h>

long sysconf(int name)
{
	switch (name) {
#ifdef _SC_PAGESIZE
	case _SC_PAGESIZE:
		return getpagesize();
#endif
#ifdef _SC_NPROCESSORS_CONF
	case _SC_NPROCESSORS_CONF:
		return 1; /* stage-1 conservative value */
#endif
#ifdef _SC_NPROCESSORS_ONLN
	case _SC_NPROCESSORS_ONLN:
		return 1; /* stage-1 conservative value */
#endif
	default:
		errno = EINVAL;
		return -1;
	}
}
