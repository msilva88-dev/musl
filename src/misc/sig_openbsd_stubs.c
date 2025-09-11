#include <signal.h>

/* musl internal wrapper used by posix_spawn/fork paths */
int __libc_sigaction(int sig, const struct sigaction *sa, struct sigaction *old)
{
	return sigaction(sig, sa, old);
}

/* musl declares: hidden void __get_handler_set(sigset_t *); */
void __get_handler_set(sigset_t *set)
{
	if (set) sigemptyset(set);
}

/* These helpers are declared with void* in musl internal headers. */
void __block_app_sigs(void *set)
{
	if (set) sigemptyset((sigset_t *)set);
}

void __restore_sigs(void *set)
{
	(void)set;
}

void __block_all_sigs(void *set)
{
	if (set) sigemptyset((sigset_t *)set);
}
