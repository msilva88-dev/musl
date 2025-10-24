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
	"Unknown signal\0"
	"Hangup\0"
	"Interrupt\0"
	"Quit\0"
	"Illegal instruction\0"
	"Trace/breakpoint trap\0"
	"Aborted\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGEMT)
	"Emulator trap\0"
#else
	"Unknown signal\0"
#endif
#elif defined(__linux__)
	"Bus error\0"
#endif
	"Arithmetic exception\0"
	"Killed\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Bus error\0"
#elif defined(__linux__)
	"User defined signal 1\0"
#endif
	"Segmentation fault\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Bad system call\0"
#elif defined(__linux__)
	"User defined signal 2\0"
#endif
	"Broken pipe\0"
	"Alarm clock\0"
	"Terminated\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Urgent I/O condition\0"
	"Stopped (signal)\0"
	"Stopped\0"
	"Continued\0"
	"Child process status\0"
#elif defined(__linux__)
#if defined(SIGSTKFLT)
	"Stack fault\0"
#elif defined(SIGEMT)
	"Emulator trap\0"
#else
	"Unknown signal\0"
#endif
	"Child process status\0"
	"Continued\0"
	"Stopped (signal)\0"
	"Stopped\0"
#endif
	"Stopped (tty input)\0"
	"Stopped (tty output)\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"I/O possible\0"
#elif defined(__linux__)
	"Urgent I/O condition\0"
#endif
	"CPU time limit exceeded\0"
	"File size limit exceeded\0"
	"Virtual timer expired\0"
	"Profiling timer expired\0"
#if defined(SIGWINCH) || defined(__linux__)
	"Window changed\0"
#else
	"Unknown signal\0"
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGINFO)
	"Information request\0"
#else
	"Unknown signal\0"
#endif
	"User defined signal 1\0"
	"User defined signal 2\0"
#if defined(SIGTHR)
	"Thread AST"
#else
	"Unknown signal"
#endif
#elif defined(__linux__)
	"I/O possible\0"
	"Power failure\0"
	"Bad system call\0"
	"RT32"
	"\0RT33\0RT34\0RT35\0RT36\0RT37\0RT38\0RT39\0RT40"
	"\0RT41\0RT42\0RT43\0RT44\0RT45\0RT46\0RT47\0RT48"
	"\0RT49\0RT50\0RT51\0RT52\0RT53\0RT54\0RT55\0RT56"
	"\0RT57\0RT58\0RT59\0RT60\0RT61\0RT62\0RT63\0RT64"
#if _NSIG > 65
	"\0RT65\0RT66\0RT67\0RT68\0RT69\0RT70\0RT71\0RT72"
	"\0RT73\0RT74\0RT75\0RT76\0RT77\0RT78\0RT79\0RT80"
	"\0RT81\0RT82\0RT83\0RT84\0RT85\0RT86\0RT87\0RT88"
	"\0RT89\0RT90\0RT91\0RT92\0RT93\0RT94\0RT95\0RT96"
	"\0RT97\0RT98\0RT99\0RT100\0RT101\0RT102\0RT103\0RT104"
	"\0RT105\0RT106\0RT107\0RT108\0RT109\0RT110\0RT111\0RT112"
	"\0RT113\0RT114\0RT115\0RT116\0RT117\0RT118\0RT119\0RT120"
	"\0RT121\0RT122\0RT123\0RT124\0RT125\0RT126\0RT127\0RT128"
#endif
#endif
	"";

char *strsignal(int signum)
{
	const char *s = strings;

	signum = sigmap(signum);
	if (signum - 1U >= _NSIG-1) signum = 0;

	for (; signum--; s++) for (; *s; s++);

	return (char *)LCTRANS_CUR(s);
}
