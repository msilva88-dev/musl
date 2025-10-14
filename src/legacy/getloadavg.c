#define _GNU_SOURCE
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#elif defined(__linux__)
#include <stdlib.h>
#include <sys/sysinfo.h>
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define __NEED_fixpt_t
#endif

int getloadavg(double *a, int n)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct loadavg ldavg;
	int r = sysctl((int[]){ CTL_VM, VM_LOADAVG }, 2, &ldavg, &(size_t){ sizeof(ldavg) }, NULL, 0);
	if (r == -1) return -1;
	double d = sizeof(ldavg.ldavg)/sizeof(fixpt_t);
	n = (n < d) ? n : d;
	for (int i=0; i<n; i++)
		a[i] = ldavg.ldavg[i]/ldavg.fscale;
#elif defined(__linux__)
	struct sysinfo si;
	if (n <= 0) return n ? -1 : 0;
	sysinfo(&si);
	if (n > 3) n = 3;
	for (int i=0; i<n; i++)
		a[i] = 1.0/(1<<SI_LOAD_SHIFT) * si.loads[i];
#endif
	return n;
}
