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

typedef unsigned long __riscv_mc_gp_state[32];

struct __riscv_mc_f_ext_state {
	unsigned int __f[32];
	unsigned int __fcsr;
};

struct __riscv_mc_d_ext_state {
	unsigned long long __f[32];
	unsigned int __fcsr;
};

struct __riscv_mc_q_ext_state {
	unsigned long long __f[64] __attribute__((__aligned__(16)));
	unsigned int __fcsr;
	unsigned int __reserved[3];
};

union __riscv_mc_fp_state {
	struct __riscv_mc_f_ext_state __f;
	struct __riscv_mc_d_ext_state __d;
	struct __riscv_mc_q_ext_state __q;
};

typedef struct mcontext_t {
	__riscv_mc_gp_state __gregs;
	union __riscv_mc_fp_state __fpregs;
} mcontext_t;

#if defined(_GNU_SOURCE)
#define REG_PC 0
#define REG_RA 1
#define REG_SP 2
#define REG_TP 4
#define REG_S0 8
#define REG_S1 9
#define REG_A0 10
#define REG_S2 18
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
typedef long breg_t;
#endif
typedef unsigned long greg_t;
typedef unsigned long gregset_t[32];
typedef union __riscv_mc_fp_state fpregset_t;
struct sigcontext {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int __sc_unused, sc_mask;
        breg_t sc_ra, sc_sp, sc_gp, sc_tp, sc_t[7], sc_s[12], sc_a[8], sc_sepc;
	breg_t sc_f[32], sc_fcsr;
	long sc_cookie;
#elif defined(__linux__)
	gregset_t gregs;
	fpregset_t fpregs;
#endif
};
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

typedef struct __ucontext
{
	unsigned long uc_flags;
	struct __ucontext *uc_link;
	stack_t uc_stack;
	sigset_t uc_sigmask;
	mcontext_t uc_mcontext;
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
#define SA_NOCLDSTOP 1
#define SA_NOCLDWAIT 2
#define SA_SIGINFO   4
#define SA_ONSTACK   0x08000000
#define SA_RESTART   0x10000000
#define SA_NODEFER   0x40000000
#define SA_RESETHAND 0x80000000
#endif

#endif

#define SIGHUP     1
#define SIGINT     2
#define SIGQUIT    3
#define SIGILL     4
#define SIGTRAP    5
#define SIGABRT    6
#define SIGIOT     SIGABRT
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define SIGEMT     7 // BSD
#elif defined(__linux__)
#define SIGBUS     7
#endif
#define SIGFPE     8
#define SIGKILL    9
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
#define _NSIG     33
#elif defined(__linux__)
#define _NSIG     65
#endif
