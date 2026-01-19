#define _BSD_SOURCE
#include <sys/mount.h>
#include "syscall.h"

int mount(const char *fstype, const char *special, int flags, void *data)
{
	return syscall(SYS_mount, fstype, special, flags, data);
}

int unmount(const char *special, int flags)
{
        return syscall(SYS_unmount, special, flags);
}

#if defined(__HyperbolaBSD__)
int umount(const char *special)
{
	return syscall(SYS_unmount, special, 0);
}

int umount2(const char *special, int flags)
{
	return syscall(SYS_unmount, special, flags);
}
#endif
