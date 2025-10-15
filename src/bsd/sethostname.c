#define _GNU_SOURCE
#include <unistd.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif

int sethostname(const char *name, size_t len)
{
	int r = sysctl((int[]){ CTL_KERN, KERN_HOSTNAME }, 2, NULL, NULL, name, len);
	return (r == -1) ? return -1 : 0;
}
