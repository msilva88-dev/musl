#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/sysctl.h>
#include <errno.h>

int sethostname(const char *name, size_t len)
{
	int mib[2] = { CTL_KERN, KERN_HOSTNAME };

	if (sysctl(mib, 2, NULL, 0, name, len) < 0) {
		return -errno;
	}

	return 0;
}
