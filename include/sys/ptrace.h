#ifndef _SYS_PTRACE_H
#define _SYS_PTRACE_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#if defined(__HyperbolaBSD__) || defined(__linux__)
#define PTRACE_TRACEME 0
#define PT_TRACE_ME PTRACE_TRACEME
#elif defined(__OpenBSD__)
#define PT_TRACE_ME 0
#endif

#if defined(__HyperbolaBSD__)
#define PTRACE_PEEKTEXT 1
#define PTRACE_PEEKDATA 2
#define PTRACE_POKETEXT 3
#define PTRACE_POKEDATA 4
#define PTRACE_CONT 7
#define PTRACE_KILL 8
#define PTRACE_ATTACH 9
#define PTRACE_DETACH 10
#define PTRACE_SINGLESTEP 32
#define PTRACE_GETREGS 33
#define PTRACE_SETREGS 34
#define PTRACE_GETFPREGS 35
#define PTRACE_SETFPREGS 36
#elif defined(__linux__)
#define PTRACE_PEEKTEXT 1
#define PTRACE_PEEKDATA 2
#define PTRACE_PEEKUSER 3
#define PTRACE_POKETEXT 4
#define PTRACE_POKEDATA 5
#define PTRACE_POKEUSER 6
#define PTRACE_CONT 7
#define PTRACE_KILL 8
#define PTRACE_SINGLESTEP 9
#define PTRACE_GETREGS 12
#define PTRACE_SETREGS 13
#define PTRACE_GETFPREGS 14
#define PTRACE_SETFPREGS 15
#define PTRACE_ATTACH 16
#define PTRACE_DETACH 17
#define PTRACE_GETFPXREGS 18
#define PTRACE_SETFPXREGS 19
#define PTRACE_SYSCALL 24
#define PTRACE_SETOPTIONS 0x4200
#define PTRACE_GETEVENTMSG 0x4201
#define PTRACE_GETSIGINFO 0x4202
#define PTRACE_SETSIGINFO 0x4203
#define PTRACE_GETREGSET 0x4204
#define PTRACE_SETREGSET 0x4205
#define PTRACE_SEIZE 0x4206
#define PTRACE_INTERRUPT 0x4207
#define PTRACE_LISTEN 0x4208
#define PTRACE_PEEKSIGINFO 0x4209
#define PTRACE_GETSIGMASK 0x420a
#define PTRACE_SETSIGMASK 0x420b
#define PTRACE_SECCOMP_GET_FILTER 0x420c
#define PTRACE_SECCOMP_GET_METADATA 0x420d
#define PTRACE_GET_SYSCALL_INFO 0x420e
#define PTRACE_GET_RSEQ_CONFIGURATION	0x420f
#endif

#if defined(__HyperbolaBSD__) || defined(__linux__)
#define PT_READ_I PTRACE_PEEKTEXT
#define PT_READ_D PTRACE_PEEKDATA
#if defined(__linux__)
#define PT_READ_U PTRACE_PEEKUSER
#endif
#define PT_WRITE_I PTRACE_POKETEXT
#define PT_WRITE_D PTRACE_POKEDATA
#if defined(__linux__)
#define PT_WRITE_U PTRACE_POKEUSER
#endif
#define PT_CONTINUE PTRACE_CONT
#define PT_KILL PTRACE_KILL
#define PT_STEP PTRACE_SINGLESTEP
#define PT_GETREGS PTRACE_GETREGS
#define PT_SETREGS PTRACE_SETREGS
#define PT_GETFPREGS PTRACE_GETFPREGS
#define PT_SETFPREGS PTRACE_SETFPREGS
#define PT_ATTACH PTRACE_ATTACH
#define PT_DETACH PTRACE_DETACH
#if defined(__linux__)
#define PT_GETFPXREGS PTRACE_GETFPXREGS
#define PT_SETFPXREGS PTRACE_SETFPXREGS
#define PT_SYSCALL PTRACE_SYSCALL
#define PT_SETOPTIONS PTRACE_SETOPTIONS
#define PT_GETEVENTMSG PTRACE_GETEVENTMSG
#define PT_GETSIGINFO PTRACE_GETSIGINFO
#define PT_SETSIGINFO PTRACE_SETSIGINFO
#endif
#elif defined(__OpenBSD__)
#define PT_READ_I 1
#define PT_READ_D 2
#define PT_WRITE_I 3
#define PT_WRITE_D 4
#define PT_CONTINUE 7
#define PT_KILL 8
#define PT_ATTACH 9
#define PT_DETACH 10
#define	PT_STEP 32
#define PT_GETREGS 33
#define PT_SETREGS 34
#define PT_GETFPREGS 35
#define PT_SETFPREGS 36
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define PT_IO 11
#define PT_SET_EVENT_MASK 12
#define PT_GET_EVENT_MASK 13
#define PT_GET_PROCESS_STATE 14
#define PT_GET_THREAD_FIRST 15
#define PT_GET_THREAD_NEXT 16
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define PIOD_READ_D 1
#define PIOD_WRITE_D 2
#define PIOD_READ_I 3
#define PIOD_WRITE_I 4
#define PIOD_READ_AUXV 5
#elif defined(__linux__)
#define PTRACE_O_TRACESYSGOOD   0x00000001
#define PTRACE_O_TRACEFORK      0x00000002
#define PTRACE_O_TRACEVFORK     0x00000004
#define PTRACE_O_TRACECLONE     0x00000008
#define PTRACE_O_TRACEEXEC      0x00000010
#define PTRACE_O_TRACEVFORKDONE 0x00000020
#define PTRACE_O_TRACEEXIT      0x00000040
#define PTRACE_O_TRACESECCOMP   0x00000080
#define PTRACE_O_EXITKILL       0x00100000
#define PTRACE_O_SUSPEND_SECCOMP 0x00200000
#define PTRACE_O_MASK           0x003000ff
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define PTRACE_FORK 2
#if defined(__HyperbolaBSD__)
#define PTRACE_EVENT_FORK PTRACE_FORK
#endif
#elif defined(__linux__)
#define PTRACE_EVENT_FORK 1
#define PTRACE_EVENT_VFORK 2
#define PTRACE_EVENT_CLONE 3
#define PTRACE_EVENT_EXEC 4
#define PTRACE_EVENT_VFORK_DONE 5
#define PTRACE_EVENT_EXIT 6
#define PTRACE_EVENT_SECCOMP 7
#define PTRACE_EVENT_STOP 128
#endif

#if defined(__linux__)
#define PTRACE_PEEKSIGINFO_SHARED 1

#define PTRACE_SYSCALL_INFO_NONE 0
#define PTRACE_SYSCALL_INFO_ENTRY 1
#define PTRACE_SYSCALL_INFO_EXIT 2
#define PTRACE_SYSCALL_INFO_SECCOMP 3
#endif

#include <bits/ptrace.h>

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
struct __ptrace_event {
	int pe_set_event;
};

struct __ptrace_io_desc {
	int piod_op;
	void *piod_offs;
	void *piod_addr;
	size_t piod_len;
};

struct __ptrace_state {
	int pe_report_event;
	pid_t pe_other_pid;
	pid_t pe_tid;
};

struct __ptrace_thread_state {
	pid_t pts_tid;
};

typedef struct __ptrace_event ptrace_event_t;
typedef struct __ptrace_state ptrace_state_t;
#elif defined(__linux__)
struct __ptrace_peeksiginfo_args {
	uint64_t off;
	uint32_t flags;
	int32_t nr;
};

struct __ptrace_seccomp_metadata {
	uint64_t filter_off;
	uint64_t flags;
};

struct __ptrace_syscall_info {
	uint8_t op;
	uint8_t __pad[3];
	uint32_t arch;
	uint64_t instruction_pointer;
	uint64_t stack_pointer;
	union {
		struct {
			uint64_t nr;
			uint64_t args[6];
		} entry;
		struct {
			int64_t rval;
			uint8_t is_error;
		} exit;
		struct {
			uint64_t nr;
			uint64_t args[6];
			uint32_t ret_data;
		} seccomp;
	};
};

struct __ptrace_rseq_configuration {
	uint64_t rseq_abi_pointer;
	uint32_t rseq_abi_size;
	uint32_t signature;
	uint32_t flags;
	uint32_t pad;
};
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int ptrace(int, pid_t, caddr_t, int);
#elif defined(__linux__)
long ptrace(int, ...);
#endif

#ifdef __cplusplus
}
#endif
#endif
