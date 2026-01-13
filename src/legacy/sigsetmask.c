#define _BSD_SOURCE
#include <signal.h>

static inline int __sigprocmask_legacy(int how, int mask)
{
	int rmask = 0;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int ret = sigprocmask(how, &mask, &rmask);
#elif defined(__linux__)
	sigset_t set = {0}, oldset = {0};
	sigemptyset(&set);
	set.__bits[0] = mask;
	int ret = sigprocmask(how, &set, &oldset);
	rmask = oldset.__bits[0];
#endif
	if (!ret) return rmask;
	return ret;
}

int sigsetmask(int mask)
{
	return __sigprocmask_legacy(SIG_SETMASK, mask);
}
