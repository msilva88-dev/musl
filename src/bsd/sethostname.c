#define _GNU_SOURCE
#include <sys/types.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include <unistd.h>

int sethostname(const char *name, size_t len)
{
	int r = sysctl((int[]){ CTL_KERN, KERN_HOSTNAME }, 2,
	    NULL, NULL, (void *)name, len);
	return (r == -1) ? -1 : 0;
}
