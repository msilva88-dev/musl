#define _BSD_SOURCE
#include <sys/types.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include <unistd.h>

int
sethostid(long hostid)
{
	int r = sysctl((int[]){ CTL_KERN, KERN_HOSTID }, 2, NULL, NULL, &hostid, sizeof hostid);
	return (r == -1) ? -1 : 0;
}
