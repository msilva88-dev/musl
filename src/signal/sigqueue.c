#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/event.h>
#include <sys/time.h>
#include <errno.h>
#include <stdlib.h>
#endif
#include <signal.h>
#include <string.h>
#include <unistd.h>
#if defined(__linux__)
#include "syscall.h"
#endif
#include "pthread_impl.h"

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static struct sigqueue_entry {
	pid_t pid;
	int sig;
	union sigval value;
	struct sigqueue_entry *next;
} *queue_head = NULL;

static int enqueue_sigqueue(pid_t pid, int sig, union sigval value)
{
	sigset_t set;
	int r = 0;
	struct sigqueue_entry *entry = malloc(sizeof(*entry));

	if (entry) {
		entry->pid = pid;
		entry->sig = sig;
		entry->value = value;

		__block_app_sigs(&set);

		entry->next = queue_head;
		queue_head = entry;

		__restore_sigs(&set);
	} else {
		r = -1;
	}

	return r;
}

#if 0
static int sigqueue_receive(union sigval *value, int *sig)
{
	sigset_t set;
	int r = 0;
	__block_app_sigs(&set);

	if (queue_head) {
		struct sigqueue_entry *entry = queue_head;
		queue_head = entry->next;
		*sig = entry->sig;
		*value = entry->value;
		free(entry);
	} else {
		r = -1;
	}

	__restore_sigs(&set);
	return r;
}
#endif /* unused */

#endif

int sigqueue(pid_t pid, int sig, const union sigval value)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	if (sig <= 0 || sig >= _NSIG) return EINVAL;
	if (enqueue_sigqueue(pid, sig, value) < 0) return ENOMEM;
	if (kill(pid, sig) < 0) return errno;
	return 0;
#elif defined(__linux__)
	siginfo_t si;
	sigset_t set;
	int r;
	memset(&si, 0, sizeof si);
	si.si_signo = sig;
	si.si_code = SI_QUEUE;
	si.si_value = value;
	si.si_uid = getuid();
	__block_app_sigs(&set);
	si.si_pid = getpid();
	r = syscall(SYS_rt_sigqueueinfo, pid, sig, &si);
	__restore_sigs(&set);
	return r;
#endif
}
