#include <sys/msg.h>
#include "syscall.h"
#if defined(__linux__)
#include "ipc.h"
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int msgrcv(int q, void *m, size_t len, long type, int flag)
#elif defined(__linux__)
ssize_t msgrcv(int q, void *m, size_t len, long type, int flag)
#endif
{
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_msgrcv, q, m, len, type, flag);
#else
	return syscall_cp(SYS_ipc, IPCOP_msgrcv, q, len, flag, ((long[]){ (long)m, type }));
#endif
}
