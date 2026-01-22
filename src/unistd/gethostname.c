#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#endif
#include <unistd.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#elif defined(__linux__)
#include <sys/utsname.h>
#endif

int gethostname(char *name, size_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
        int r = sysctl((int[]){ CTL_KERN, KERN_HOSTNAME }, 2, name, &len, NULL, 0);
        if (r == -1) return -1;
#elif defined(__linux__)
	size_t i;
	struct utsname uts;
	if (uname(&uts)) return -1;
	if (len > sizeof uts.nodename) len = sizeof uts.nodename;
	for (i=0; i<len && (name[i] = uts.nodename[i]); i++);
	if (i && i==len) name[i-1] = 0;
#endif
	return 0;
}
