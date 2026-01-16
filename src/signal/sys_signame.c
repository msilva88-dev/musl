/*
 * Copyright (c) 1983 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* sys_signame from OpenBSD 7.0 source code: lib/libc/gen/signame.c */

#define _BSD_SOURCE
#include <signal.h>

const char *const __sys_signame[NSIG] = {
	"0",
	"HUP",		/* SIGHUP */
	"INT",		/* SIGINT */
	"QUIT",		/* SIGQUIT */
	"ILL",		/* SIGILL */
	"TRAP",		/* SIGTRAP */
	"ABRT",		/* SIGABRT */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGEMT)
	"EMT",		/* SIGEMT */
#else
	"7",
#endif
#elif defined(__linux__)
	"BUS",		/* SIGBUS */
#endif
	"FPE",		/* SIGFPE */
	"KILL",		/* SIGKILL */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"BUS",		/* SIGBUS */
#elif defined(__linux__)
	"USR1",		/* SIGUSR1 */
#endif
	"SEGV",		/* SIGSEGV */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"SYS",		/* SIGSYS */
#elif defined(__linux__)
	"USR2",		/* SIGUSR2 */
#endif
	"PIPE",		/* SIGPIPE */
	"ALRM",		/* SIGALRM */
	"TERM",		/* SIGTERM */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"URG",		/* SIGURG */
	"STOP",		/* SIGSTOP */
	"TSTP",		/* SIGTSTP */
	"CONT",		/* SIGCONT */
	"CHLD",		/* SIGCHLD */
#elif defined(__linux__)
#if defined(SIGSTKFLT)
	"STKFLT",	/* SIGSTKFLT */
#elif defined(SIGEMT)
	"EMT",		/* SIGEMT */
#else
	"16",
#endif
	"CHLD",		/* SIGCHLD */
	"CONT",		/* SIGCONT */
	"STOP",		/* SIGSTOP */
	"TSTP",		/* SIGTSTP */
#endif
	"TTIN",		/* SIGTTIN */
	"TTOU",		/* SIGTTOU */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"POLL",		/* SIGIO/SIGPOLL */
#elif defined(__linux__)
	"URG",		/* SIGURG */
#endif
	"XCPU",		/* SIGXCPU */
	"XFSZ",		/* SIGXFSZ */
	"VTALRM",	/* SIGVTALRM */
	"PROF",		/* SIGPROF */
#if defined(SIGWINCH) || defined(__linux__)
	"WINCH",	/* SIGWINCH */
#else
	"28",
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGINFO)
	"INFO",		/* SIGINFO */
#else
	"29",
#endif
	"USR1",		/* SIGUSR1 */
	"USR2",		/* SIGUSR2 */
#if defined(SIGTHR)
	"THR"		/* SIGTHR */
#else
	"32"
#endif
#elif defined(__linux__)
	"POLL",		/* SIGIO/SIGPOLL */
	"PWD",		/* SIGPWD */
	"SYS",		/* SIGSYS */
	"32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42",
	"43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53",
	"54", "55", "56", "57", "58", "59", "60", "61", "62", "63",
#if _NSIG > 65
	"64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74",
	"75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85",
	"86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96",
	"97", "98", "99", "100", "101", "102", "103", "104", "105", "106",
	"107", "108", "109", "110", "111", "112", "113", "114", "115", "116",
	"117", "118", "119", "120", "121", "122", "123", "124", "125", "126",
	"127", "128"
#else
	"64"
#endif
#endif
};
strong_alias(__sys_signame, sys_signame);
