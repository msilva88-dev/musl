/* OpenBSD uname() using sysctl(3) — Stage-1 bring-up.
 *
 * Fields:
 *   sysname  ← kern.ostype
 *   nodename ← kern.hostname
 *   release  ← kern.osrelease
 *   version  ← kern.version
 *   machine  ← hw.machine
 */
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <string.h>
#include <errno.h>

static int sysctl_str(int mib0, int mib1, char *dst, size_t dstsz)
{
	int mib[2] = { mib0, mib1 };
	char buf[256];
	size_t len = sizeof buf;
	if (!dst || dstsz == 0) { errno = EFAULT; return -1; }
	if (sysctl(mib, 2, buf, &len, 0, 0) == -1) return -1;
	/* ensure NUL termination and truncation */
	if (len >= sizeof buf) len = sizeof buf - 1;
	buf[len] = 0;
	size_t n = len < dstsz-1 ? len : dstsz-1;
	memcpy(dst, buf, n);
	dst[n] = 0;
	return 0;
}

int uname(struct utsname *u)
{
	if (!u) { errno = EFAULT; return -1; }
	/* zero to avoid leaking stack junk if any sysctl fails after copies */
	memset(u, 0, sizeof *u);

	if (sysctl_str(CTL_KERN, KERN_OSTYPE, u->sysname,  sizeof u->sysname)  == -1) return -1;
	if (sysctl_str(CTL_KERN, KERN_HOSTNAME, u->nodename, sizeof u->nodename) == -1) return -1;
	if (sysctl_str(CTL_KERN, KERN_OSRELEASE, u->release, sizeof u->release) == -1) return -1;
	if (sysctl_str(CTL_KERN, KERN_VERSION, u->version,  sizeof u->version)  == -1) return -1;
	if (sysctl_str(CTL_HW,   HW_MACHINE,   u->machine,  sizeof u->machine)  == -1) return -1;

	return 0;
}
