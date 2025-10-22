#include <sys/sem.h>
#include <stdarg.h>
#if defined(__linux__)
#include <endian.h>
#endif
#include "syscall.h"
#if defined(__linux__)
#include "ipc.h"
#endif

#if defined(__linux__)
#if __BYTE_ORDER != __BIG_ENDIAN
#undef SYSCALL_IPC_BROKEN_MODE
#endif
#endif

union semun {
	int val;
	struct semid_ds *buf;
	unsigned short *array;
};

int semctl(int id, int num, int cmd, ...)
{
	union semun arg = {0};
	va_list ap;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	switch (cmd) {
#elif defined(__linux__)
	switch (cmd & ~IPC_TIME64) {
#endif
	case SETVAL: case GETALL: case SETALL: case IPC_SET:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	case IPC_STAT:
#elif defined(__linux__)
	case IPC_INFO: case SEM_INFO:
	case IPC_STAT & ~IPC_TIME64:
	case SEM_STAT & ~IPC_TIME64:
	case SEM_STAT_ANY & ~IPC_TIME64:
#endif
		va_start(ap, cmd);
		arg = va_arg(ap, union semun);
		va_end(ap);
	}
#if defined(__linux__)
#if IPC_TIME64
	struct semid_ds out, *orig;
	if (cmd&IPC_TIME64) {
		out = (struct semid_ds){0};
		orig = arg.buf;
		arg.buf = &out;
	}
#endif
#ifdef SYSCALL_IPC_BROKEN_MODE
	struct semid_ds tmp;
	if (cmd == IPC_SET) {
		tmp = *arg.buf;
		tmp.sem_perm.mode *= 0x10000U;
		arg.buf = &tmp;
	}
#endif
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int r = __syscall(SYS___semctl, id, num, cmd, &arg);
#elif defined(__linux__)
#ifndef SYS_ipc
	int r = __syscall(SYS_semctl, id, num, IPC_CMD(cmd), arg.buf);
#else
	int r = __syscall(SYS_ipc, IPCOP_semctl, id, num, IPC_CMD(cmd), &arg.buf);
#endif
#ifdef SYSCALL_IPC_BROKEN_MODE
	if (r >= 0) switch (cmd | IPC_TIME64) {
	case IPC_STAT:
	case SEM_STAT:
	case SEM_STAT_ANY:
		arg.buf->sem_perm.mode >>= 16;
	}
#endif
#if IPC_TIME64
	if (r >= 0 && (cmd&IPC_TIME64)) {
		arg.buf = orig;
		*arg.buf = out;
		IPC_HILO(arg.buf, sem_otime);
		IPC_HILO(arg.buf, sem_ctime);
	}
#endif
#endif
	return __syscall_ret(r);
}
