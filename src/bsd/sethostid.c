#include <sys/sysctl.h>
#include <unistd.h>

int
sethostid(long hostid)
{
	int r = sysctl((int[]){ CTL_KERN, KERN_HOSTID }, 2, NULL, NULL, &hostid, sizeof hostid);
	return (r == -1) ? -1 : 0;
}
