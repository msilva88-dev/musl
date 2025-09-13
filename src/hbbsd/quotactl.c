#include <sys/quota.h>
#include "syscall.h"

int quotactl(const char *path, int cmd, int id, char *addr)
{
	return syscall(SYS_quotactl, path, cmd, id, addr);
}
