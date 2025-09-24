#define _GNU_SOURCE
#include <sys/time.h>
#include "syscall.h"

int adjtime(const struct timeval *in, struct timeval *out)
{
	return syscall(SYS_adjtime, in, out);
}
