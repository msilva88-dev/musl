#define _GNU_SOURCE
#include <unistd.h>
#include "pthread_impl.h"

pid_t getthrid(void)
{
	return __pthread_self()->tid;
}
