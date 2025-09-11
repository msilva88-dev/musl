/* OpenBSD: there is no SYS_setdomainname.  Provide a stub for Stage-1. */
#include <stddef.h>
#include <errno.h>

int setdomainname(const char *name, size_t len)
{
	(void)name; (void)len;
	errno = ENOSYS;
	return -1;
}
