#if defined(__HyperbolaBSD__)
#include <sys/quota.h>
#elif defined(__OpenBSD__)
#include <ufs/ufs/quota.h>
#include <unistd.h>
#endif
#include "syscall.h"

int quotactl(const char *path, int cmd, int id, char *addr)
{
	return syscall(SYS_quotactl, path, cmd, id, addr);
}
