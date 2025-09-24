#define _GNU_SOURCE
#include <unistd.h>
#include "syscall.h"

// syncfs_wrapper

int syncfs_compat(int fd __attribute__((unused))) {
	(void)fd;

	return sync();
}
