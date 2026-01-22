#include <signal.h>
#include <limits.h>

int sigfillset(sigset_t *set)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	*set = ~0U;
#elif defined(__linux__)
#if ULONG_MAX == 0xffffffff
	set->__bits[0] = 0x7ffffffful;
	set->__bits[1] = 0xfffffffcul;
	if (_NSIG > 65) {
		set->__bits[2] = 0xfffffffful;
		set->__bits[3] = 0xfffffffful;
	}
#else
	set->__bits[0] = 0xfffffffc7ffffffful;
	if (_NSIG > 65) set->__bits[1] = 0xfffffffffffffffful;
#endif
#endif
	return 0;
}
