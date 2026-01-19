/*-
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 1995 Peter Wemm
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* setproctitle/setproctitle_fast from FreeBSD 14.1 source code: lib/libc/gen/setproctitle.c */

#define _BSD_SOURCE
#include <sys/types.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/exec.h>
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/exec.h>
#include <sys/sysctl.h>
#endif
#include <elf.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "libc.h"

#define SPT_BUFSIZE 2048	/* from other parts of sendmail */

static char *
setproctitle_internal(const char *fmt, va_list ap)
{
	static struct ps_strings *ps_strings;
	static char *buf = NULL;
	static char *obuf = NULL;
	static char **oargv;
	static int oargc = -1;
	static char *nargv[2] = { NULL, NULL };
	char **nargvp;
	int nargc;
	int i;
	size_t len;

	if (buf == NULL) {
		buf = malloc(SPT_BUFSIZE);
		if (buf == NULL)
			return NULL;
		nargv[0] = buf;
	}

	if (obuf == NULL) {
		obuf = malloc(SPT_BUFSIZE);
		if (obuf == NULL)
			return NULL;
		*obuf = '\0';
	}

	if (fmt) {
		buf[SPT_BUFSIZE - 1] = '\0';

		if (fmt[0] == '-') {
			/* skip program name prefix */
			fmt++;
			len = 0;
		} else {
			/* print program name heading for grep */
			(void)snprintf(buf, SPT_BUFSIZE, "%s: ", __progname);
			len = strlen(buf);
		}

		/* print the argument string */
		(void)vsnprintf(buf + len, SPT_BUFSIZE - len, fmt, ap);

		nargvp = nargv;
		nargc = 1;
	} else if (*obuf != '\0') {
		/* Idea from NetBSD - reset the title on fmt == NULL */
		nargvp = oargv;
		nargc = oargc;
	} else
		/* Nothing to restore */
		return NULL;

	if (ps_strings == NULL) {
		int oid[] = { CTL_VM, VM_PSSTRINGS };
		struct ps_strings *__ps_strings;
		size_t __ps_len = sizeof(__ps_strings);
		int r = sysctl(oid, 2, &__ps_strings, &__ps_len, NULL, 0);
		if (!r) ps_strings = __ps_strings;
		return NULL;
	}

	/*
	 * PS_STRINGS points to zeroed memory on a style #2 kernel.
	 * Should not happen.
	 */
	if (ps_strings->ps_argvstr == NULL)
		return NULL;

	/* style #3 */
	if (oargc == -1) {
		/* Record our original args */
		oargc = ps_strings->ps_nargvstr;
		oargv = ps_strings->ps_argvstr;
		for (i = len = 0; i < oargc; i++) {
			/*
			 * The program may have scribbled into its
			 * argv array, e.g., to remove some arguments.
			 * If that has happened, break out before
			 * trying to call strlen on a NULL pointer.
			 */
			if (oargv[i] == NULL) {
				oargc = i;
				break;
			}
			snprintf(obuf + len, SPT_BUFSIZE - len, "%s%s",
			    len != 0 ? " " : "", oargv[i]);
			if (len != 0)
				len++;
			len += strlen(oargv[i]);
			if (len >= SPT_BUFSIZE)
				break;
		}
	}
	ps_strings->ps_nargvstr = nargc;
	ps_strings->ps_argvstr = nargvp;

	return nargvp[0];
}

static int fast_update = 0;

#if defined(__HyperbolaBSD__)
void setproctitle_fast(const char *fmt, ...)
{
	va_list ap;
	char *buf;
	int oid[4];

	va_start(ap, fmt);
	buf = setproctitle_internal(fmt, ap);
	va_end(ap);

	if (buf && !fast_update) {
		/* Tell the kernel to start looking in user-space */
		oid[0] = CTL_KERN;
		oid[1] = KERN_PROC;
		oid[2] = KERN_PROC_ARGS;
		oid[3] = -1;
		sysctl(oid, 4, NULL, NULL, "", 0);
		fast_update = 1;
	}
}
#endif

void setproctitle(const char *fmt, ...)
{
	va_list ap;
	char *buf;
	int oid[4];

	va_start(ap, fmt);
	buf = setproctitle_internal(fmt, ap);
	va_end(ap);

	if (buf != NULL) {
		/* Set the title into the kernel cached command line */
		oid[0] = CTL_KERN;
		oid[1] = KERN_PROC;
		oid[2] = KERN_PROC_ARGS;
		oid[3] = -1;
		sysctl(oid, 4, NULL, NULL, buf, strlen(buf) + 1);
		fast_update = 0;
	}
}
