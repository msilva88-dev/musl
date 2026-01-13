#define _BSD_SOURCE
#include <signal.h>
#include <stddef.h>

int sigvec(int sig, struct sigvec *newvec, struct sigvec *oldvec)
{
	struct sigaction newaction = {
		.sa_flags = newvec ? newvec->sv_flags & ~(SA_NODEFER|SA_ONSTACK|SA_RESTART) : 0,
		.sa_handler = newvec ? newvec->sv_handler : NULL,
		.sa_mask = newvec ? newvec->sv_mask : 0
#if defined(__linux__)
		, .sa_restorer = NULL
#endif
	}, oldaction = { 0 };
	if (newvec && !(newvec->sv_flags & SV_HOLD)) newaction.sa_flags |= SA_NODEFER;
	if (newvec && !(newvec->sv_flags & SV_INTERRUPT)) newaction.sa_flags |= SA_RESTART;
	if (newvec && !(newvec->sv_flags & SV_ONSTACK)) newaction.sa_flags |= SA_ONSTACK;
	int ret = sigaction(sig, newvec ? &newaction : NULL, oldvec ? &oldaction : NULL);
	if (!ret && oldvec) {
		oldvec->sv_flags = oldaction.sa_flags & ~(SA_NODEFER|SA_ONSTACK|SA_RESTART);
		if (!(oldaction.sa_flags & SA_NODEFER)) oldvec->sv_flags |= SV_HOLD;
		if (oldaction.sa_flags & SA_ONSTACK) oldvec->sv_flags |= SV_ONSTACK;
		if (!(oldaction.sa_flags & SA_RESTART)) oldvec->sv_flags |= SV_INTERRUPT;
		oldvec->sv_handler = oldaction.sa_handler;
		int mask = 0;
		for (int sigbit = 1; sigbit < NSIG; sigbit++) {
			if (sigismember(&oldaction.sa_mask, sigbit))
				mask |= 1 << (sigbit - 1);
			}
		oldvec->sv_mask = mask;
	};
	return ret;
}
