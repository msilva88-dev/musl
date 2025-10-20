#include <sys/sem.h>
#include "syscall.h"
#include "ipc.h"

int semop(int id, struct sembuf *buf, size_t n)
{
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_semop, id, buf, n);
#else
	return syscall(SYS_ipc, IPCOP_semop, id, n, 0, buf);
#endif
}
