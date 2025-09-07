/* Minimal OpenBSD sysconf() for Stage-1 bring-up.
 * Only implements the pieces we need without pulling Linux-only paths.
 */
#include <unistd.h>
#include <errno.h>
/* Ensure kernel sysctl.h sees the real system typedefs, not musl shims. */
#ifdef MUSL_OBSD
#include "/usr/include/sys/types.h"
#include "/usr/include/stdint.h"
#endif
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/types.h>  /* still fine if included twice; keeps POSIX names */

static long sc_ncpu(int mib1)
{
	int mib[2] = { CTL_HW, mib1 };
	int n = 0;
	size_t len = sizeof n;
	if (sysctl(mib, 2, &n, &len, 0, 0) == -1 || len != sizeof n || n <= 0)
		return 1; /* conservative fallback */
	return n;
}

long sysconf(int name)
{
	switch (name) {
#ifdef _SC_PAGESIZE
	case _SC_PAGESIZE:
		return getpagesize();
#endif
#ifdef _SC_NPROCESSORS_CONF
	case _SC_NPROCESSORS_CONF:
		return sc_ncpu(HW_NCPU);
#endif
#ifdef _SC_NPROCESSORS_ONLN
	case _SC_NPROCESSORS_ONLN:
#ifdef HW_NCPUONLINE
		return sc_ncpu(HW_NCPUONLINE);
#else
		return sc_ncpu(HW_NCPU);
#endif
#endif
	default:
		errno = EINVAL;
		return -1;
	}
}
