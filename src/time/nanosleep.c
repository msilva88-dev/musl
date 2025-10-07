#include <time.h>
#include "syscall.h"

int nanosleep(const struct timespec *req, struct timespec *rem)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_nanosleep, req, rem);
#elif defined(__linux__)
	return __syscall_ret(-__clock_nanosleep(CLOCK_REALTIME, 0, req, rem));
#endif
}
