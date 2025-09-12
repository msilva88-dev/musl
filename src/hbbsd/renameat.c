#define _GNU_SOURCE
#include <stdio.h>
#include "syscall.h"

int renameat(int fromfd, const char *from, int tofd, const char *to)
{
	return syscall(SYS_renameat, fromfd, from, tofd, to);
}
