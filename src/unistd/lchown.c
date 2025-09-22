#include <unistd.h>
#include <fcntl.h>
#include "syscall.h"

int lchown(const char *path, uid_t uid, gid_t gid)
{
#if defined(SYS_lchown) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_lchown, path, uid, gid);
#else
	return syscall(SYS_fchownat, AT_FDCWD, path, uid, gid, AT_SYMLINK_NOFOLLOW);
#endif
}
