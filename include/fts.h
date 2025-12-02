/*
 * Copyright (c) 1989, 1993
 *      The Regents of the University of California.  All rights reserved.
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

/* fts header from OpenBSD 7.0 source code: include/fts.h */

#ifndef _FTS_H
#define _FTS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stat.h>

enum __fts_options {
	FTS_COMFOLLOW = 000001,
	FTS_LOGICAL = 000002,
	FTS_NOCHDIR = 000004,
	FTS_NOSTAT = 000010,
	FTS_PHYSICAL = 000020,
	FTS_SEEDOT = 000040,
	FTS_XDEV = 000100,
	FTS_OPTIONMASK = 000377,
	FTS_NAMEONLY = 010000,
	FTS_STOP = 020000
};

enum __ftsent_flags {
	FTS_DONTCHDIR = 1,
	FTS_SYMFOLLOW
};

enum __ftsent_info {
	FTS_D = 1,
	FTS_DC,
	FTS_DEFAULT,
	FTS_DNR,
	FTS_DOT,
	FTS_DP,
	FTS_ERR,
	FTS_F,
	FTS_INIT,
	FTS_NS,
	FTS_NSOK,
	FTS_SL,
	FTS_SLNONE
};

enum __ftsent_instr {
	FTS_AGAIN = 1,
	FTS_FOLLOW,
	FTS_NOINSTR,
	FTS_SKIP
};

enum __ftsent_level {
	FTS_ROOTPARENTLEVEL = -1,
	FTS_ROOTLEVEL,
	FTS_MAXLEVEL = 0x7fffffff
};

#define __FTS_NAMESZ 1

struct __ftsent {
	struct __ftsent *fts_cycle, *fts_parent, *fts_link;
	long fts_number;
	void *fts_pointer;
	char *fts_accpath, *fts_path;
	int fts_errno, fts_symfd;
	size_t fts_pathlen, fts_namelen;
	ino_t fts_ino;
	dev_t fts_dev;
	nlink_t fts_nlink;
	int fts_level;
	unsigned short fts_info, fts_flags, fts_instr, fts_spare;
	struct stat *fts_statp;
	char fts_name[__FTS_NAMESZ];
};

struct __fts {
	struct __ftsent *fts_cur, *fts_child, **fts_array;
	dev_t fts_dev;
	char *fts_path;
	int fts_rfd;
	size_t fts_pathlen;
	int fts_nitems, (*fts_compar)(), fts_options;
};

typedef struct __ftsent ftsent_t;
typedef struct __fts fts_t;

#define FTS fts_t;
#define FTSENT ftsent_t;

FTSENT *fts_children(FTS *, int);
int fts_close(FTS *);
FTS *fts_open(char * const *, int, int (*)(const FTSENT **, const FTSENT **));
FTSENT *fts_read(FTS *);
int fts_set(FTS *, FTSENT *, int);

#ifdef __cplusplus
}
#endif

#endif
