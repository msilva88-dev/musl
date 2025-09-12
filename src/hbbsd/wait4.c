#define _GNU_SOURCE
#include <sys/wait.h>
#include <sys/resource.h>
#include <string.h>
#include <errno.h>
#include "syscall.h"

pid_t wait4(pid_t pid, int *status, int options, struct rusage *ru)
{
	int r;
	char *dest = ru ? (char *)&ru->ru_maxrss - 4*sizeof(long) : 0;
	r = __sys_wait4(pid, status, options, dest);
	if (r>0 && ru && sizeof(time_t) > sizeof(long)) {
		long kru[4];
		memcpy(kru, dest, 4*sizeof(long));
		ru->ru_utime = (struct timeval)
			{ .tv_sec = kru[0], .tv_usec = kru[1] };
		ru->ru_stime = (struct timeval)
			{ .tv_sec = kru[2], .tv_usec = kru[3] };
	}
	return __syscall_ret(r);
}
