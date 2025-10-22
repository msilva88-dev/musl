#include <sys/msg.h>
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

int msgctl(int q, int cmd, struct msqid_ds *buf)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int r = __syscall(SYS_msgctl, q, cmd, buf);
#elif defined(__linux__)
#if IPC_TIME64
	struct msqid_ds out, *orig;
	if (cmd&IPC_TIME64) {
		out = (struct msqid_ds){0};
		orig = buf;
		buf = &out;
	}
#endif
#ifdef SYSCALL_IPC_BROKEN_MODE
	struct msqid_ds tmp;
	if (cmd == IPC_SET) {
		tmp = *buf;
		tmp.msg_perm.mode *= 0x10000U;
		buf = &tmp;
	}
#endif
#ifndef SYS_ipc
	int r = __syscall(SYS_msgctl, q, IPC_CMD(cmd), buf);
#else
	int r = __syscall(SYS_ipc, IPCOP_msgctl, q, IPC_CMD(cmd), 0, buf, 0);
#endif
#ifdef SYSCALL_IPC_BROKEN_MODE
	if (r >= 0) switch (cmd | IPC_TIME64) {
	case IPC_STAT:
	case MSG_STAT:
	case MSG_STAT_ANY:
		buf->msg_perm.mode >>= 16;
	}
#endif
#if IPC_TIME64
	if (r >= 0 && (cmd&IPC_TIME64)) {
		buf = orig;
		*buf = out;
		IPC_HILO(buf, msg_stime);
		IPC_HILO(buf, msg_rtime);
		IPC_HILO(buf, msg_ctime);
	}
#endif
#endif
	return __syscall_ret(r);
}
