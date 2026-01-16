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

char *__strsignal_name(int signum)
{
	const char *s = strings;

	signum = sigmap(signum);
	if (signum - 1U >= _NSIG-1) signum = 0;

	for (; signum--; s++) for (; *s; s++);

	return (char *)LCTRANS_CUR(s);
}

/*
const char *const sys_signame[] = {
	__strsignal_name(0), __strsignal_name(1), __strsignal_name(2), __strsignal_name(3),
	__strsignal_name(4), __strsignal_name(5), __strsignal_name(6), __strsignal_name(7),
	__strsignal_name(8), __strsignal_name(9), __strsignal_name(10), __strsignal_name(11),
	__strsignal_name(12), __strsignal_name(13), __strsignal_name(14), __strsignal_name(15),
	__strsignal_name(16), __strsignal_name(17), __strsignal_name(18), __strsignal_name(19),
	__strsignal_name(20), __strsignal_name(21), __strsignal_name(22), __strsignal_name(23),
	__strsignal_name(24), __strsignal_name(25), __strsignal_name(26), __strsignal_name(27),
	__strsignal_name(28), __strsignal_name(29), __strsignal_name(30), __strsignal_name(31),
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	__strsignal_name(32)
#elif defined(__linux__)
	__strsignal_name(32), __strsignal_name(33), __strsignal_name(34), __strsignal_name(35),
	__strsignal_name(36), __strsignal_name(37), __strsignal_name(38), __strsignal_name(39),
	__strsignal_name(40), __strsignal_name(41), __strsignal_name(42), __strsignal_name(43),
	__strsignal_name(44), __strsignal_name(45), __strsignal_name(46), __strsignal_name(47),
	__strsignal_name(48), __strsignal_name(49), __strsignal_name(50), __strsignal_name(51),
	__strsignal_name(52), __strsignal_name(53), __strsignal_name(54), __strsignal_name(55),
	__strsignal_name(56), __strsignal_name(57), __strsignal_name(58), __strsignal_name(59),
	__strsignal_name(60), __strsignal_name(61), __strsignal_name(62), __strsignal_name(63),
#if _NSIG > 65
	__strsignal_name(64), __strsignal_name(65), __strsignal_name(66), __strsignal_name(67),
	__strsignal_name(68), __strsignal_name(69), __strsignal_name(70), __strsignal_name(71),
	__strsignal_name(72), __strsignal_name(73), __strsignal_name(74), __strsignal_name(75),
	__strsignal_name(76), __strsignal_name(77), __strsignal_name(78), __strsignal_name(79),
	__strsignal_name(80), __strsignal_name(81), __strsignal_name(82), __strsignal_name(83),
	__strsignal_name(84), __strsignal_name(85), __strsignal_name(86), __strsignal_name(87),
	__strsignal_name(88), __strsignal_name(89), __strsignal_name(90), __strsignal_name(91),
	__strsignal_name(92), __strsignal_name(93), __strsignal_name(94), __strsignal_name(95),
	__strsignal_name(96), __strsignal_name(97), __strsignal_name(98), __strsignal_name(99),
	__strsignal_name(100), __strsignal_name(101), __strsignal_name(102), __strsignal_name(103),
	__strsignal_name(104), __strsignal_name(105), __strsignal_name(106), __strsignal_name(107),
	__strsignal_name(108), __strsignal_name(109), __strsignal_name(110), __strsignal_name(111),
	__strsignal_name(112), __strsignal_name(113), __strsignal_name(114), __strsignal_name(115),
	__strsignal_name(116), __strsignal_name(117), __strsignal_name(118), __strsignal_name(119),
	__strsignal_name(120), __strsignal_name(121), __strsignal_name(122), __strsignal_name(123),
	__strsignal_name(124), __strsignal_name(125), __strsignal_name(126), __strsignal_name(127),
	__strsignal_name(128)
#else
	__strsignal_name(64)
#endif
#endif
};
*/

/*
const char *const sys_siglist[] = {
	strsignal(0), strsignal(1), strsignal(2), strsignal(3), strsignal(4), strsignal(5),
	strsignal(6), strsignal(7), strsignal(8), strsignal(9), strsignal(10), strsignal(11),
	strsignal(12), strsignal(13), strsignal(14), strsignal(15), strsignal(16), strsignal(17),
	strsignal(18), strsignal(19), strsignal(20), strsignal(21), strsignal(22), strsignal(23),
	strsignal(24), strsignal(25), strsignal(26), strsignal(27), strsignal(28), strsignal(29),
	strsignal(30), strsignal(31),
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	strsignal(32)
#elif defined(__linux__)
	strsignal(32), strsignal(33), strsignal(34), strsignal(35), strsignal(36), strsignal(37),
	strsignal(38), strsignal(39), strsignal(40), strsignal(41), strsignal(42), strsignal(43),
	strsignal(44), strsignal(45), strsignal(46), strsignal(47), strsignal(48), strsignal(49),
	strsignal(50), strsignal(51), strsignal(52), strsignal(53), strsignal(54), strsignal(55),
	strsignal(56), strsignal(57), strsignal(58), strsignal(59), strsignal(60), strsignal(61),
	strsignal(62), strsignal(63)
#if _NSIG > 65
	strsignal(64), strsignal(65), strsignal(66), strsignal(67), strsignal(68), strsignal(69),
	strsignal(70), strsignal(71), strsignal(72), strsignal(73), strsignal(74), strsignal(75),
	strsignal(76), strsignal(77), strsignal(78), strsignal(79), strsignal(80), strsignal(81),
	strsignal(82), strsignal(83), strsignal(84), strsignal(85), strsignal(86), strsignal(87),
	strsignal(88), strsignal(89), strsignal(90), strsignal(91), strsignal(92), strsignal(93),
	strsignal(94), strsignal(95), strsignal(96), strsignal(97), strsignal(98), strsignal(99),
	strsignal(100), strsignal(101), strsignal(102), strsignal(103), strsignal(104), strsignal(105),
	strsignal(106), strsignal(107), strsignal(108), strsignal(109), strsignal(110), strsignal(111),
	strsignal(112), strsignal(113), strsignal(114), strsignal(115), strsignal(116), strsignal(117),
	strsignal(118), strsignal(119), strsignal(120), strsignal(121), strsignal(122), strsignal(123),
	strsignal(124), strsignal(125), strsignal(126), strsignal(127), strsignal(128)
#else
	strsignal(64)
#endif
#endif
};
*/
