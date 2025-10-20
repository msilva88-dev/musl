#include <sys/shm.h>
#include "syscall.h"
#include "ipc.h"

void *shmat(int id, const void *addr, int flag)
{
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return (void *)syscall(SYS_shmat, id, addr, flag);
#else
	unsigned long ret;
	ret = syscall(SYS_ipc, IPCOP_shmat, id, flag, &addr, addr);
	return (ret > -(unsigned long)SHMLBA) ? (void *)ret : (void *)addr;
#endif
}
