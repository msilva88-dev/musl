#define _BSD_SOURCE
#include <signal.h>
#include <string.h>
#include "locale_impl.h"

#if !defined(SIGABRT) && defined(SIGIOT)
#define SIGABRT SIGIOT
#endif

#if !defined(SIGCHLD) && defined(SIGCLD)
#define SIGCHLD SIGCLD
#endif

#if !defined(SIGPOLL) && defined(SIGIO)
#define SIGPOLL SIGIO
#endif

#if ((defined(__HyperbolaBSD__) || defined(__OpenBSD__)) \
 && (SIGHUP == 1) && (SIGINT == 2) && (SIGQUIT == 3) && (SIGILL == 4) \
 && (SIGTRAP == 5) && (SIGABRT == 6) && ((defined(SIGEMT) && SIGEMT == 7) || !defined(SIGEMT)) && (SIGFPE == 8) \
 && (SIGKILL == 9) && (SIGBUS == 10) && (SIGSEGV == 11) && (SIGSYS == 12) \
 && (SIGPIPE == 13) && (SIGALRM == 14) && (SIGTERM == 15) && (SIGURG == 16) \
 && (SIGSTOP == 17) && (SIGTSTP == 18) && (SIGCONT == 19) && (SIGCHLD == 20) \
 && (SIGTTIN == 21) && (SIGTTOU == 22) && ((defined(SIGPOLL) && SIGPOLL == 23) || !defined(SIGPOLL)) && (SIGXCPU == 24) \
 && (SIGXFSZ == 25) && (SIGVTALRM == 26) && (SIGPROF == 27) && ((defined(SIGWINCH) && SIGWINCH == 28) || !defined(SIGWINCH)) \
 && ((defined(SIGINFO) && SIGINFO == 29) || !defined(SIGINFO)) && (SIGUSR1 == 30) && (SIGUSR2 == 31) \
 && ((defined(SIGTHR) && SIGTHR == 31) || !defined(SIGTHR)) \
 ) || (defined(__linux__) \
 && (SIGHUP == 1) && (SIGINT == 2) && (SIGQUIT == 3) && (SIGILL == 4) \
 && (SIGTRAP == 5) && (SIGABRT == 6) && (SIGBUS == 7) && (SIGFPE == 8) \
 && (SIGKILL == 9) && (SIGUSR1 == 10) && (SIGSEGV == 11) && (SIGUSR2 == 12) \
 && (SIGPIPE == 13) && (SIGALRM == 14) && (SIGTERM == 15) && (SIGSTKFLT == 16) \
 && (SIGCHLD == 17) && (SIGCONT == 18) && (SIGSTOP == 19) && (SIGTSTP == 20) \
 && (SIGTTIN == 21) && (SIGTTOU == 22) && (SIGURG == 23) && (SIGXCPU == 24) \
 && (SIGXFSZ == 25) && (SIGVTALRM == 26) && (SIGPROF == 27) && (SIGWINCH == 28) \
 && (SIGPOLL == 29) && (SIGPWR == 30) && (SIGSYS == 31) \
 )

#define sigmap(x) x

#else

static const char map[] = {
	[SIGHUP]    = 1,
	[SIGINT]    = 2,
	[SIGQUIT]   = 3,
	[SIGILL]    = 4,
	[SIGTRAP]   = 5,
	[SIGABRT]   = 6,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGEMT)
	[SIGEMT]    = 7,
#endif
#elif defined(__linux__)
	[SIGBUS]    = 7,
#endif
	[SIGFPE]    = 8,
	[SIGKILL]   = 9,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	[SIGBUS]    = 10,
#elif defined(__linux__)
	[SIGUSR1]   = 10,
#endif
	[SIGSEGV]   = 11,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	[SIGSYS]    = 12,
#elif defined(__linux__)
	[SIGUSR2]   = 12,
#endif
	[SIGPIPE]   = 13,
	[SIGALRM]   = 14,
	[SIGTERM]   = 15,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	[SIGURG]    = 16,
	[SIGSTOP]   = 17,
	[SIGTSTP]   = 18,
	[SIGCONT]   = 19,
	[SIGCHLD]   = 20,
#elif defined(__linux__)
#if defined(SIGSTKFLT)
	[SIGSTKFLT] = 16,
#elif defined(SIGEMT)
	[SIGEMT]    = 16,
#endif
	[SIGCHLD]   = 17,
	[SIGCONT]   = 18,
	[SIGSTOP]   = 19,
	[SIGTSTP]   = 20,
#endif
	[SIGTTIN]   = 21,
	[SIGTTOU]   = 22,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGPOLL)
	[SIGPOLL]   = 23,
#endif
#elif defined(__linux__)
	[SIGURG]    = 23,
#endif
	[SIGXCPU]   = 24,
	[SIGXFSZ]   = 25,
	[SIGVTALRM] = 26,
	[SIGPROF]   = 27,
#if defined(SIGWINCH) || defined(__linux__)
	[SIGWINCH]  = 28,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGINFO)
	[SIGINFO]   = 29,
#endif
	[SIGUSR1]   = 30,
#if defined(SIGTHR)
	[SIGUSR2]   = 31,
	[SIGTHR]    = 32
#else
	[SIGUSR2]   = 31
#endif
#elif defined(__linux__)
	[SIGPOLL]   = 29,
	[SIGPWR]    = 30,
	[SIGSYS]    = 31
#endif
};

#define sigmap(x) ((x) >= sizeof map ? (x) : map[(x)])

#endif

static const char strings[] =
	"0\0"
	"HUP\0"
	"INT\0"
	"QUIT\0"
	"ILL\0"
	"TRAP\0"
	"ABRT\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGEMT)
	"EMT\0"
#else
	"7\0"
#endif
#elif defined(__linux__)
	"BUS\0"
#endif
	"FPE\0"
	"KILL\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"BUS\0"
#elif defined(__linux__)
	"USR1\0"
#endif
	"SEGV\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"SYS\0"
#elif defined(__linux__)
	"USR2\0"
#endif
	"PIPE\0"
	"ALRM\0"
	"TERM\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"URG\0"
	"STOP\0"
	"TSTP\0"
	"CONT\0"
	"CHLD\0"
#elif defined(__linux__)
#if defined(SIGSTKFLT)
	"STKFLT\0"
#elif defined(SIGEMT)
	"EMT\0"
#else
	"16\0"
#endif
	"CHLD\0"
	"CONT\0"
	"STOP\0"
	"TSTP\0"
#endif
	"TTIN\0"
	"TTOU\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"POLL\0"
#elif defined(__linux__)
	"URG\0"
#endif
	"XCPU\0"
	"XFSZ\0"
	"VTALRM\0"
	"PROF\0"
#if defined(SIGWINCH) || defined(__linux__)
	"WINCH\0"
#else
	"28\0"
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGINFO)
	"INFO\0"
#else
	"29\0"
#endif
	"USR1\0"
	"USR2\0"
#if defined(SIGTHR)
	"THR"
#else
	"32"
#endif
#elif defined(__linux__)
	"POLL\0"
	"PWD\0"
	"SYS\0"
	"32"
	"\033\034\035\036\037\038\039\040"
	"\041\042\043\044\045\046\047\048"
	"\049\050\051\052\053\054\055\056"
	"\057\058\059\060\061\062\063\064"
#if _NSIG > 65
	"\065\066\067\068\069\070\071\072"
	"\073\074\075\076\077\078\079\080"
	"\081\082\083\084\085\086\087\088"
	"\089\090\091\092\093\094\095\096"
	"\097\098\099\0100\0101\0102\0103\0104"
	"\0105\0106\0107\0108\0109\0110\0111\0112"
	"\0113\0114\0115\0116\0117\0118\0119\0120"
	"\0121\0122\0123\0124\0125\0126\0127\0128"
#endif
#endif
	"";

char *strsignal_name(int signum)
{
	const char *s = strings;

	signum = sigmap(signum);
	if (signum - 1U >= _NSIG-1) signum = 0;

	for (; signum--; s++) for (; *s; s++);

	return (char *)LCTRANS_CUR(s);
}

// Non-thread-safe: shared static buffer overwritten on each call
const char * const *sys_signamef(void)
{
	static const char *strsigname[_NSIG];
	for (int i = 0; i < _NSIG; i++) strsigname[i] = strsignal_name(i);
	return strsigname;
}

// Thread-safe, reentrant: the caller provides their own buffer
void sys_signamef_r(const char **strbuf)
{
	for (int i = 0; i < _NSIG; i++) strbuf[i] = strsignal_name(i);
}

// Non-thread-safe: shared static buffer overwritten on each call
const char * const *sys_siglistf(void)
{
	static const char *strsiglist[_NSIG];
	for (int i = 0; i < _NSIG; i++) strsiglist[i] = strsignal(i);
	return strsiglist;
}

// Thread-safe, reentrant: the caller provides their own buffer
void sys_siglistf_r(const char **strbuf)
{
	for (int i = 0; i < _NSIG; i++) strbuf[i] = strsignal(i);
}
