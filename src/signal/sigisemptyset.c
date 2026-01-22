#define _GNU_SOURCE
#include <signal.h>
#include <string.h>

int sigisemptyset(const sigset_t *set)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return *set == 0;
#elif defined(__linux__)
	for (size_t i=0; i<_NSIG/8/sizeof *set->__bits; i++)
		if (set->__bits[i]) return 0;
	return 1;
#endif
}
