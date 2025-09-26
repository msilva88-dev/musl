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
enum { REG_R8 = 0 };
#define REG_R8 REG_R8
enum { REG_R9 = 1 };
#define REG_R9 REG_R9
enum { REG_R10 = 2 };
#define REG_R10 REG_R10
enum { REG_R11 = 3 };
#define REG_R11 REG_R11
enum { REG_R12 = 4 };
#define REG_R12 REG_R12
enum { REG_R13 = 5 };
#define REG_R13 REG_R13
enum { REG_R14 = 6 };
#define REG_R14 REG_R14
enum { REG_R15 = 7 };
#define REG_R15 REG_R15
enum { REG_RDI = 8 };
#define REG_RDI REG_RDI
enum { REG_RSI = 9 };
#define REG_RSI REG_RSI
enum { REG_RBP = 10 };
#define REG_RBP REG_RBP
enum { REG_RBX = 11 };
#define REG_RBX REG_RBX
enum { REG_RDX = 12 };
#define REG_RDX REG_RDX
enum { REG_RAX = 13 };
#define REG_RAX REG_RAX
enum { REG_RCX = 14 };
#define REG_RCX REG_RCX
enum { REG_RSP = 15 };
#define REG_RSP REG_RSP
enum { REG_RIP = 16 };
#define REG_RIP REG_RIP
enum { REG_EFL = 17 };
#define REG_EFL REG_EFL
enum { REG_CSGSFS = 18 };
#define REG_CSGSFS REG_CSGSFS
enum { REG_ERR = 19 };
#define REG_ERR REG_ERR
enum { REG_TRAPNO = 20 };
#define REG_TRAPNO REG_TRAPNO
enum { REG_OLDMASK = 21 };
#define REG_OLDMASK REG_OLDMASK
enum { REG_CR2 = 22 };
#define REG_CR2 REG_CR2
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
typedef long long greg_t, gregset_t[23];
typedef struct _fpstate {
	unsigned short cwd, swd, ftw, fop;
	unsigned long long rip, rdp;
	unsigned mxcsr, mxcr_mask;
	struct {
		unsigned short significand[4], exponent, padding[3];
	} _st[8];
	struct {
		unsigned element[4];
	} _xmm[16];
	unsigned padding[24];
} *fpregset_t;
struct sigcontext {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long sc_rdi, sc_rsi, sc_rdx, sc_rcx,
	long sc_r8, sc_r9, sc_r10, sc_r11, sc_r12, sc_r13, sc_r14, sc_r15;
        long sc_rbp, sc_rbx, sc_rax, sc_gs, sc_fs, sc_es, sc_ds, sc_trapno;
        long sc_err, sc_rip, sc_cs, sc_rflags, sc_rsp, sc_ss;
        struct fxsave64 {
		uint16_t fx_fcw, fx_fsw;
		uint8_t fx_ftw, fx_unused1;
		uint16_t fx_fop;
		uint64_t fx_rip, fx_rdp;
		uint32_t fx_mxcsr, fx_mxcsr_mask;
		uint64_t fx_st[8][2], fx_xmm[16][2];
		uint8_t fx_unused3[96];
	} __attribute__((__packed__)) *sc_fpstate;
        int __sc_unused, sc_mask;
        long sc_cookie;
#elif defined(__linux__)
	unsigned long r8, r9, r10, r11, r12, r13, r14, r15;
	unsigned long rdi, rsi, rbp, rbx, rdx, rax, rcx, rsp, rip, eflags;
	unsigned short cs, gs, fs, __pad0;
	unsigned long err, trapno, oldmask, cr2;
	struct _fpstate *fpstate;
	unsigned long __reserved1[8];
#endif
};
typedef struct {
	gregset_t gregs;
	fpregset_t fpregs;
	unsigned long long __reserved1[8];
} mcontext_t;
#else
typedef struct {
	unsigned long __space[32];
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
	unsigned long __fpregs_mem[64];
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
