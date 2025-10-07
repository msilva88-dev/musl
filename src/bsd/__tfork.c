#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

pid_t __tfork(const struct __tfork *params, size_t psize)
{
	return __syscall(SYS___tfork, params, psize);
}

pid_t __tfork_thread(
	const struct __tfork *params,
	size_t psize,
	void (*startfunc)(void *),
	void *startarg
)
{
	pid_t ret = __syscall(SYS___tfork, params, psize);
	if (ret < 0) return -1;
	else if (ret != 0) return ret;
	if (startfunc) startfunc(startarg);
	__syscall(SYS___threxit, 0);
	return ret;
}
