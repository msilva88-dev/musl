#include <signal.h>
#include <errno.h>

/* musl internal wrapper used by posix_spawn/fork paths */
int __libc_sigaction(int sig, const struct sigaction *sa, struct sigaction *old)
{
	return sigaction(sig, sa, old);
}

/* musl uses this to know which signals have user handlers installed.
 * Stage-2: report none to keep behavior simple.
 */
int __get_handler_set(sigset_t *set)
{
	if (!set) return 0;
	return sigemptyset(set);
}
