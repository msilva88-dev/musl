#define _GNU_SOURCE
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#if defined(__linux__)
#include <sys/prctl.h>
#endif

#include "pthread_impl.h"

int pthread_setname_np(pthread_t thread, const char *name)
{
	int fd, cs, status = 0;
#if defined(__linux__)
	char f[sizeof "/proc/self/task//comm" + 3*sizeof(int)];
#endif
	size_t len;

	if ((len = strnlen(name, 16)) > 15) return ERANGE;

	if (thread == pthread_self())
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		strlcpy(thread->name, name, sizeof(thread->name));
		return 0;
#elif defined(__linux__)
		return prctl(PR_SET_NAME, (unsigned long)name, 0UL, 0UL, 0UL) ? errno : 0;
#endif

#if defined(__linux__)
	snprintf(f, sizeof f, "/proc/self/task/%d/comm", thread->tid);
#endif
	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
	if ((fd = open(f, O_WRONLY|O_CLOEXEC)) < 0 || write(fd, name, len) < 0) status = errno;
	if (fd >= 0) close(fd);
	pthread_setcancelstate(cs, 0);
	return status;
}
