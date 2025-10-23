#define _BSD_SOURCE
#include <sys/time.h>
#include "syscall.h"

int adjfreq(const int64_t *freq, int64_t *oldfreq)
{
	return syscall(SYS_adjfreq, freq, oldfreq);
}
