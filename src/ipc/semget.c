#include <sys/sem.h>
#include <limits.h>
#include <errno.h>
#include "syscall.h"
#if defined(__linux__)
#include "ipc.h"
#endif

int semget(key_t key, int n, int fl)
{
	/* The kernel uses the wrong type for the sem_nsems member
	 * of struct semid_ds, and thus might not check that the
	 * n fits in the correct (per POSIX) userspace type, so
	 * we have to check here. */
	if (n > USHRT_MAX) return __syscall_ret(-EINVAL);
#if !defined(SYS_ipc) || defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall(SYS_semget, key, n, fl);
#else
	return syscall(SYS_ipc, IPCOP_semget, key, n, fl);
#endif
}
