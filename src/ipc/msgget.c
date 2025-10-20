#include <sys/msg.h>
#include "syscall.h"
#include "ipc.h"

int msgget(key_t k, int flag)
{
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_msgget, k, flag);
#else
	return syscall(SYS_ipc, IPCOP_msgget, k, flag);
#endif
}
