#define _GNU_SOURCE
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/types.h>
#endif
#include <unistd.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#elif defined(__linux__)
#include <sys/utsname.h>
#include <string.h>
#include <errno.h>
#endif

int getdomainname(char *name, size_t len)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int r = sysctl((int[]){ CTL_KERN, KERN_DOMAINNAME }, 2, name, &len, NULL, 0);
	if (r == -1) return -1;
#elif defined(__linux__)
	struct utsname temp;
	uname(&temp);
	if (!len || strlen(temp.domainname) >= len) {
		errno = EINVAL;
		return -1;
	}
	strcpy(name, temp.domainname);
#endif
	return 0;
}
