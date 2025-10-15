#define _GNU_SOURCE
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include <unistd.h>
#include "libc.h"

int getpagesize(void)
{

	if (!PAGE_SIZE) {
		int r = sysctl(
			(int[]){ CTL_HW, HW_PAGESIZE },
			2,
			PAGE_SIZE,
			&(size_t){ sizeof(PAGE_SIZE) },
			NULL,
			0
		);
		if (r == -1) return -1;
	}

	return PAGE_SIZE;
}
