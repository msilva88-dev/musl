#include <signal.h>
#include <unistd.h>

/* OpenBSD stage-1: ensure default action, then raise SIGABRT. */
void abort(void)
{
	struct sigaction sa;
	sa.sa_handler = SIG_DFL;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = 0;
	(void)sigaction(SIGABRT, &sa, 0);
	(void)raise(SIGABRT);
	/* Fallback if signal was blocked/ignored somehow. */
	_Exit(127);
}
