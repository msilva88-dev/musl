/* OpenBSD Stage-1: waitid(2) is not available.
 * Provide a minimal stub to unblock the static bootstrap.
 */
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>

int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options)
{
	(void)idtype;
	(void)id;
	(void)infop;
	(void)options;
	errno = ENOSYS;
	return -1;
}
