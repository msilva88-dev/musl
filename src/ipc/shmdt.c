#include <sys/shm.h>
#include "syscall.h"
#if defined(__linux__)
#include "ipc.h"
#endif

int shmdt(const void *addr)
{
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_shmdt, addr);
#else
	return syscall(SYS_ipc, IPCOP_shmdt, 0, 0, 0, addr);
#endif
}
