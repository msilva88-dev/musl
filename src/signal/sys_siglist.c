/*
 * Copyright (c) 1983, 1993
 *	The Regents of the University of California.  All rights reserved.
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

/* sys_siglist from OpenBSD 7.0 source code: lib/libc/gen/siglist.c */

#define _BSD_SOURCE
#include <signal.h>

const char *const __sys_siglist[NSIG] = {
	"Unknown signal",
	"Hangup",			/* SIGHUP */
	"Interrupt",			/* SIGINT */
	"Quit",				/* SIGQUIT */
	"Illegal instruction",		/* SIGILL */
	"Trace/breakpoint trap",	/* SIGTRAP */
	"Aborted",			/* SIGABRT */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGEMT)
	"Emulator trap",		/* SIGEMT */
#else
	"Unknown signal",
#endif
#elif defined(__linux__)
	"Bus error",			/* SIGBUS */
#endif
	"Arithmetic exception",		/* SIGFPE */
	"Killed",			/* SIGKILL */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Bus error",			/* SIGBUS */
#elif defined(__linux__)
	"User defined signal 1",	/* SIGUSR1 */
#endif
	"Segmentation fault",		/* SIGSEGV */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Bad system call",		/* SIGSYS */
#elif defined(__linux__)
	"User defined signal 2",	/* SIGUSR2 */
#endif
	"Broken pipe",			/* SIGPIPE */
	"Alarm clock",			/* SIGALRM */
	"Terminated",			/* SIGTERM */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"Urgent I/O condition",		/* SIGURG */
	"Stopped (signal)",		/* SIGSTOP */
	"Stopped",			/* SIGTSTP */
	"Continued",			/* SIGCONT */
	"Child process status",		/* SIGCHLD */
#elif defined(__linux__)
#if defined(SIGSTKFLT)
	"Stack fault",			/* SIGSTKFLT */
#elif defined(SIGEMT)
	"Emulator trap",		/* SIGEMT */
#endif
	"Child process status",		/* SIGCHLD */
	"Continued",			/* SIGCONT */
	"Stopped (signal)",		/* SIGSTOP */
	"Stopped",			/* SIGTSTP */
#endif
	"Stopped (tty input)",		/* SIGTTIN */
	"Stopped (tty output)",		/* SIGTTOU */
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"I/O possible",			/* SIGIO/SIGPOLL */
#elif defined(__linux__)
	"Urgent I/O condition",		/* SIGURG */
#endif
	"CPU time limit exceeded",	/* SIGXCPU */
	"File size limit exceeded",	/* SIGXFSZ */
	"Virtual timer expired",	/* SIGVTALRM */
	"Profiling timer expired",	/* SIGPROF */
#if defined(SIGWINCH) || defined(__linux__)
	"Window size changes",		/* SIGWINCH */
#else
	"Unknown signal",
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(SIGINFO)
	"Information request",		/* SIGINFO */
#else
	"Unknown signal",
#endif
	"User defined signal 1",	/* SIGUSR1 */
	"User defined signal 2",	/* SIGUSR2 */
#if defined(SIGTHR)
	"Thread AST"			/* SIGTHR */
#else
	"Unknown signal"
#endif
#elif defined(__linux__)
	"I/O possible",			/* SIGIO/SIGPOLL */
	"Power failure",		/* SIGPWR */
	"Bad system call",		/* SIGSYS */
	"RT32", "RT33", "RT34", "RT35", "RT36", "RT37", "RT38", "RT39",
	"RT40", "RT41", "RT42", "RT43", "RT44", "RT45", "RT46", "RT47",
	"RT48", "RT49", "RT50", "RT51", "RT52", "RT53", "RT54", "RT55",
	"RT56", "RT57", "RT58", "RT59", "RT60", "RT61", "RT62", "RT63",
#if _NSIG > 65
	"RT64", "RT65", "RT66", "RT67", "RT68", "RT69", "RT70", "RT71",
	"RT72", "RT73", "RT74", "RT75", "RT76", "RT77", "RT78", "RT79",
	"RT80", "RT81", "RT82", "RT83", "RT84", "RT85", "RT86", "RT87",
	"RT88", "RT89", "RT90", "RT91", "RT92", "RT93", "RT94", "RT95",
	"RT96", "RT97", "RT98", "RT99", "RT100", "RT101", "RT102", "RT103",
	"RT104", "RT105", "RT106", "RT107", "RT108", "RT109", "RT110",
	"RT111", "RT112", "RT113", "RT114", "RT115", "RT116", "RT117",
	"RT118", "RT119", "RT120", "RT121", "RT122", "RT123", "RT124",
	"RT125", "RT126", "RT127", "RT128"
#else
	"RT64"
#endif
#endif
};
strong_alias(__sys_siglist, sys_siglist);
