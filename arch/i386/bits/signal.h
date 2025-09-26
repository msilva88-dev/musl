#if defined(_POSIX_SOURCE) || defined(_POSIX_C_SOURCE) \
 || defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)

#if defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define MINSIGSTKSZ 12288
#define SIGSTKSZ 28672
#elif defined(__linux__)
#define MINSIGSTKSZ 2048
#define SIGSTKSZ 8192
#endif
#endif

#ifdef _GNU_SOURCE
enum { REG_GS = 0 };
#define REG_GS REG_GS
enum { REG_FS = 1 };
#define REG_FS REG_FS
enum { REG_ES = 2 };
#define REG_ES REG_ES
enum { REG_DS = 3 };
#define REG_DS REG_DS
enum { REG_EDI = 4 };
#define REG_EDI REG_EDI
enum { REG_ESI = 5 };
#define REG_ESI REG_ESI
enum { REG_EBP = 6 };
#define REG_EBP REG_EBP
enum { REG_ESP = 7 };
#define REG_ESP REG_ESP
enum { REG_EBX = 8 };
#define REG_EBX REG_EBX
enum { REG_EDX = 9 };
#define REG_EDX REG_EDX
enum { REG_ECX = 10 };
#define REG_ECX REG_ECX
enum { REG_EAX = 11 };
#define REG_EAX REG_EAX
enum { REG_TRAPNO = 12 };
#define REG_TRAPNO REG_TRAPNO
enum { REG_ERR = 13 };
#define REG_ERR REG_ERR
enum { REG_EIP = 14 };
#define REG_EIP REG_EIP
enum { REG_CS = 15 };
#define REG_CS REG_CS
enum { REG_EFL = 16 };
#define REG_EFL REG_EFL
enum { REG_UESP = 17 };
#define REG_UESP REG_UESP
enum { REG_SS = 18 };
#define REG_SS REG_SS
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
typedef int greg_t, gregset_t[19];
typedef struct _fpstate {
	unsigned long cw, sw, tag, ipoff, cssel, dataoff, datasel;
	struct {
		unsigned short significand[4], exponent;
	} _st[8];
	unsigned long status;
} *fpregset_t;
struct sigcontext {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int sc_gs, sc_fs, sc_es, sc_ds;
	int sc_edi, sc_esi, sc_ebp, sc_ebx, sc_edx, sc_ecx, sc_eax;
	int sc_eip, sc_cs, sc_eflags, sc_esp, sc_ss;
#define sc_sp sc_esp
#define sc_fp sc_ebp
#define sc_pc sc_eip
#define sc_ps sc_eflags
	long sc_cookie;
	int sc_mask, sc_trapno, sc_err;
	union savefpu {
		struct save87 {
			struct env87 {
				long en_cw, en_sw, en_tw, en_fip;
				unsigned short en_fcs, en_opcode;
				long en_foo, en_fos;
			} sv_env;
			struct fpacc87 {
				unsigned char fp_bytes[10];
			} sv_ac[8];
			unsigned long sv_ex_sw, sv_ex_tw;
		} sv_87;
		struct savexmm {
			struct envxmm {
				uint16_t en_cw, en_sw;
				uint8_t en_tw, en_rsvd0;
				uint16_t en_opcode;
				uint32_t en_fip;
				uint16_t en_fcs, en_rsvd1;
				uint32_t en_foo;
				uint16_t en_fos, en_rsvd2;
				uint32_t en_mxcsr, en_mxcsr_mask;
			} sv_env;
			struct fpaccxmm {
				uint8_t fp_bytes[10], fp_rsvd[6];
			} sv_ac[8];
			struct xmmreg {
				uint8_t sse_bytes[16];
			} sv_xmmregs[8];
			uint8_t sv_rsvd[16 * 14];
			uint32_t sv_ex_sw, sv_ex_tw;
		} sv_xmm;
	} *sc_fpstate;
#elif defined(__linux__)
	unsigned short gs, __gsh, fs, __fsh, es, __esh, ds, __dsh;
	unsigned long edi, esi, ebp, esp, ebx, edx, ecx, eax;
	unsigned long trapno, err, eip;
	unsigned short cs, __csh;
	unsigned long eflags, esp_at_signal;
	unsigned short ss, __ssh;
	struct _fpstate *fpstate;
	unsigned long oldmask, cr2;
#endif
};
typedef struct {
	gregset_t gregs;
	fpregset_t fpregs;
	unsigned long oldmask, cr2;
} mcontext_t;
#else
typedef struct {
	unsigned __space[22];
} mcontext_t;
#endif

struct sigaltstack {
	void *ss_sp;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	size_t ss_size;
	int ss_flags;
#elif defined(__linux__)
	int ss_flags;
	size_t ss_size;
#endif
};

typedef struct __ucontext {
	unsigned long uc_flags;
	struct __ucontext *uc_link;
	stack_t uc_stack;
	mcontext_t uc_mcontext;
	sigset_t uc_sigmask;
	unsigned long __fpregs_mem[28];
} ucontext_t;

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SA_NOCLDSTOP  8
#define SA_NOCLDWAIT  0x00000020
#define SA_SIGINFO    0x00000040
#define SA_ONSTACK    1
#define SA_RESTART    2
#define SA_NODEFER    0x00000010
#define SA_RESETHAND  4
#elif defined(__linux__)
#define SA_NOCLDSTOP  1
#define SA_NOCLDWAIT  2
#define SA_SIGINFO    4
#define SA_ONSTACK    0x08000000
#define SA_RESTART    0x10000000
#define SA_NODEFER    0x40000000
#define SA_RESETHAND  0x80000000
#define SA_RESTORER   0x04000000
#endif

#endif

#define SIGHUP    1
#define SIGINT    2
#define SIGQUIT   3
#define SIGILL    4
#define SIGTRAP   5
#define SIGABRT   6
#define SIGIOT    SIGABRT
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGEMT    7 // BSD
#elif defined(__linux__)
#define SIGBUS    7
#endif
#define SIGFPE    8
#define SIGKILL   9
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGBUS    10 // 7
#elif defined(__linux__)
#define SIGUSR1   10
#endif
#define SIGSEGV   11
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGSYS    12 // 31
#elif defined(__linux__)
#define SIGUSR2   12
#endif
#define SIGPIPE   13
#define SIGALRM   14
#define SIGTERM   15
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGURG    16 // 23
#define SIGSTOP   17 // 19
#define SIGTSTP   18 // 20
#define SIGCONT   19 // 18
#define SIGCHLD   20 // 17
#elif defined(__linux__)
#define SIGSTKFLT 16
#define SIGCHLD   17
#define SIGCONT   18
#define SIGSTOP   19
#define SIGTSTP   20
#endif
#define SIGTTIN   21
#define SIGTTOU   22
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGIO     23 // 29
#elif defined(__linux__)
#define SIGURG    23
#endif
#define SIGXCPU   24
#define SIGXFSZ   25
#define SIGVTALRM 26
#define SIGPROF   27
#define SIGWINCH  28
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGINFO   29 // BSD
#define SIGUSR1   30 // 10
#define SIGUSR2   31 // 12
#define SIGTHR    32 // BSD
#elif defined(__linux__)
#define SIGIO     29
#define SIGPWR    30
#define SIGSYS    31
#endif
#define SIGPOLL   SIGIO
#define SIGUNUSED SIGSYS

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _NSIG 33
#elif defined(__linux__)
#define _NSIG 65
#endif
