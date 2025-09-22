#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int chown(const char *path, uid_t uid, gid_t gid)
{
#if defined(SYS_chown) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_chown, path, uid, gid);
#else
	return syscall(SYS_fchownat, AT_FDCWD, path, uid, gid, 0);
#endif
}
