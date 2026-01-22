#include <signal.h>
#include <string.h>

int sigemptyset(sigset_t *set)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	*set = 0;
#elif defined(__linux__)
	set->__bits[0] = 0;
	if (sizeof(long)==4 || _NSIG > 65) set->__bits[1] = 0;
	if (sizeof(long)==4 && _NSIG > 65) {
		set->__bits[2] = 0;
		set->__bits[3] = 0;
	}
#endif
	return 0;
}
