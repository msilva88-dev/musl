#define _GNU_SOURCE
#include <fcntl.h>
#include <unistd.h>
#if defined(__linux__)
#include <sys/prctl.h>
#endif

#include "pthread_impl.h"

int pthread_getname_np(pthread_t thread, char *name, size_t len)
{
	int fd, cs, status = 0;
#if defined(__linux__)
	char f[sizeof "/proc/self/task//comm" + 3*sizeof(int)];
#endif

	if (len < 16) return ERANGE;

	if (thread == pthread_self())
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		strlcpy(name, thread->name, len);
		return 0;
#elif defined(__linux__)
		return prctl(PR_GET_NAME, (unsigned long)name, 0UL, 0UL, 0UL) ? errno : 0;
#endif

#if defined(__linux__)
	snprintf(f, sizeof f, "/proc/self/task/%d/comm", thread->tid);
#endif
	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
	if ((fd = open(f, O_RDONLY|O_CLOEXEC)) < 0 || (len = read(fd, name, len)) == -1) status = errno;
	else name[len-1] = 0; /* remove trailing new line only if successful */
	if (fd >= 0) close(fd);
	pthread_setcancelstate(cs, 0);
	return status;
}
