#include <sys/swap.h>
#include "syscall.h"

int swapctl(int cmd, const void *arg, int misc)
{
	return syscall(SYS_swapctl, cmd, arg, misc);
}

int swapon(const char *path, int flags)
{
	return syscall(SYS_swapctl, SWAP_ON, path, flags);
}

int swapoff(const char *path)
{
	return syscall(SYS_swapctl, SWAP_OFF, path, 0);
}
