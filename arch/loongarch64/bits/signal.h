#if defined(_POSIX_SOURCE) || defined(_POSIX_C_SOURCE) \
 || defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)

#if defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#if defined(__HyperbolaBSD__)
#define MINSIGSTKSZ 12288
#define SIGSTKSZ 28672
#elif defined(__linux__)
#define MINSIGSTKSZ 4096
#define SIGSTKSZ 16384
#endif
#endif

#if defined(_GNU_SOURCE)
#define LARCH_NGREG 32
#define LARCH_REG_RA 1
#define LARCH_REG_SP 3
#define LARCH_REG_S0 23
#define LARCH_REG_S1 24
#define LARCH_REG_A0 4
#define LARCH_REG_S2 25
#define LARCH_REG_NARGS 8
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
typedef unsigned long greg_t, gregset_t[32];

struct sigcontext {
	unsigned long sc_pc;
	unsigned long sc_regs[32];
	unsigned sc_flags;
	unsigned long sc_extcontext[] __attribute__((__aligned__(16)));
};
#endif

typedef struct {
	unsigned long __pc;
	unsigned long __gregs[32];
	unsigned __flags;
	unsigned long __extcontext[] __attribute__((__aligned__(16)));
} mcontext_t;

struct sigaltstack {
	void *ss_sp;
#if defined(__HyperbolaBSD__)
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
	long __uc_pad;
	mcontext_t uc_mcontext;
} ucontext_t;

#define __uc_flags uc_flags

#if defined(__HyperbolaBSD__)
#define SA_NOCLDSTOP 8
#define SA_NOCLDWAIT 0x00000020
#define SA_SIGINFO   0x00000040
#define SA_ONSTACK   1
#define SA_RESTART   2
#define SA_NODEFER   0x00000010
#define SA_RESETHAND 4
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
#if defined(__HyperbolaBSD__)
#define SIGEMT     7 // BSD
#elif defined(__linux__)
#define SIGBUS     7
#endif
#define SIGFPE     8
#define SIGKILL    9
#if defined(__HyperbolaBSD__)
#define SIGBUS    10 // 7
#elif defined(__linux__)
#define SIGUSR1   10
#endif
#define SIGSEGV   11
#if defined(__HyperbolaBSD__)
#define SIGSYS    12 // 31
#elif defined(__linux__)
#define SIGUSR2   12
#endif
#define SIGPIPE   13
#define SIGALRM   14
#define SIGTERM   15
#if defined(__HyperbolaBSD__)
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
#if defined(__HyperbolaBSD__)
#define SIGIO     23 // 29
#elif defined(__linux__)
#define SIGURG    23
#endif
#define SIGXCPU   24
#define SIGXFSZ   25
#define SIGVTALRM 26
#define SIGPROF   27
#define SIGWINCH  28
#if defined(__HyperbolaBSD__)
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

#if defined(__HyperbolaBSD__)
#define _NSIG 33
#elif defined(__linux__)
#define _NSIG 65
#endif
