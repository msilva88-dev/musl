#ifndef _SYS_MSG_H
#define _SYS_MSG_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/ipc.h>

#define __NEED_pid_t
#define __NEED_key_t
#define __NEED_time_t
#define __NEED_size_t
#define __NEED_ssize_t

#include <bits/alltypes.h>

typedef unsigned long msgqnum_t;
typedef unsigned long msglen_t;

#include <bits/msg.h>

#define __msg_cbytes msg_cbytes

#define MSG_NOERROR 010000
#if defined(__linux__)
#define MSG_EXCEPT  020000

#define MSG_STAT (11 | (IPC_STAT & 0x100))
#define MSG_INFO 12
#define MSG_STAT_ANY (13 | (IPC_STAT & 0x100))

struct msginfo {
	int msgpool, msgmap, msgmax, msgmnb, msgmni, msgssz, msgtql;
	unsigned short msgseg;
};
#endif

int msgctl (int, int, struct msqid_ds *);
int msgget (key_t, int);
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int msgrcv (int, void *, size_t, long, int);
#elif defined(__linux__)
ssize_t msgrcv (int, void *, size_t, long, int);
#endif
int msgsnd (int, const void *, size_t, int);

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define mymsg msgbuf
#endif
struct msgbuf {
	long mtype;
	char mtext[1];
};
#endif

#ifdef __cplusplus
}
#endif

#endif
