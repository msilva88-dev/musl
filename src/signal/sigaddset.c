#include <signal.h>
#include <errno.h>

int sigaddset(sigset_t *set, int sig)
{
	unsigned s = sig-1;
	if (s >= _NSIG-1 || sig-32U < 3) {
		errno = EINVAL;
		return -1;
	}
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	*set |= 1U << s;
#elif defined(__linux__)
	set->__bits[s/8/sizeof *set->__bits] |= 1UL<<(s&8*sizeof *set->__bits-1);
#endif
	return 0;
}
