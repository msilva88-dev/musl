#include <sys/swap.h>
#include <stdlib.h>
#include <string.h>
#include "syscall.h"

int swapctl(int cmd, const void *arg, int misc)
{
	return syscall(SYS_swapctl, cmd, arg, misc);
}

#if defined(__HyperbolaBSD__)
int swapon(const char *path, int flags)
{
	int prio = (flags & SWAP_FLAG_PRIO_MASK) >> SWAP_FLAG_PRIO_SHIFT;
	if (flags & SWAP_FLAG_PREFER) prio += 10;

	int n = __syscall(SYS_swapctl, SWAP_NSWAP, NULL, 0);
	if (n <= 0) return syscall(SYS_swapctl, SWAP_ON, path, prio);

	struct swapent *swtab = calloc(n, sizeof(*swtab));
	if (!swtab) {
		errno = ENOMEM;
		return -1;
	}

	if (syscall(SYS_swapctl, SWAP_STATS, swtab, n) == -1) {
		free(swtab);
		return -1;
	}

	for (int i = 0; i < n; i++) {
		if ((swtab[i].se_flags & SWF_INUSE) && strcmp(swtab[i].se_path, path) == 0) {
			int old_prio = swtab[i].se_priority;
			free(swtab);
			if (old_prio != prio) return syscall(SYS_swapctl, SWAP_CTL, path, prio);
			return 0;
		}
	}

	free(swtab);
	return syscall(SYS_swapctl, SWAP_ON, path, prio);
}

int swapoff(const char *path)
{
	return syscall(SYS_swapctl, SWAP_OFF, path, 0);
}
#endif
