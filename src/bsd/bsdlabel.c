/*
 * Copyright (c) 1983, 1987, 1993
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

/* bsdlabel from OpenBSD 7.0 source code: lib/libc/gen/disklabel.c */

#define _BSD_SOURCE
#if defined(__HyperbolaBSD__)
#include <hyperbk/bsdlabel.h>
#include <hyperbk/vfs/ffs/fs.h>
#elif defined(__OpenBSD__)
#include <sys/disklabel.h>
#include <ufs/ffs/fs.h>
#endif

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>

static unsigned int gettype(char *t, const char * const *names)
{
	const char * const *nm;

	for (nm = names; *nm; nm++)
		if (strcasecmp(t, *nm) == 0)
			return nm - names;
	if (isdigit((unsigned char)*t))
		return (unsigned int)strtonum(t, 0, USHRT_MAX, NULL);
	return 0;
}

#if defined(__HyperbolaBSD__)
struct disklabel;
typedef struct bsdlabel bsdlabel_t;
#define __BSDL_TC__(d) (struct disklabel *)(d)
#elif defined(__OpenBSD__)
typedef struct disklabel bsdlabel_t;
#define BSDLABELV1_FFS_FRAGBLOCK(s, f) DISKLABELV1_FFS_FRAGBLOCK(s, f)
#define BSDL_SETPSIZE(p, f) DL_SETPSIZE(p, f)
#define SDMAGIC DISKMAGIC
#define _PATH_SDTAB _PATH_DISKTAB
#define __BSDL_TC__(d) (d)
#define sdtypenames dktypenames
#endif

static bsdlabel_t *__getsdbyname(const char *name)
{
	static bsdlabel_t bsdl;
	bsdlabel_t *bsdlp = &bsdl;
	struct partition *pp;
	char *buf;
	char *db_array[2] = { _PATH_SDTAB, 0 };
	char *cp, *cq;
	char p, max, psize[3], pbsize[3],
		pfsize[3], poffset[3], ptype[3];
	uint32_t *dx;

	if (cgetent(&buf, db_array, (char *) name) < 0)
		return NULL;

	memset(&bsdl, 0, sizeof(bsdl));
	/*
	 * typename
	 */
	cq = bsdlp->d_typename;
	cp = buf;
	while (cq < bsdlp->d_typename + sizeof(bsdlp->d_typename) - 1 &&
	    (*cq = *cp) && *cq != '|' && *cq != ':')
		cq++, cp++;
	*cq = '\0';

	if (cgetcap(buf, "sf", ':') != NULL)
		bsdlp->d_flags |= D_BADSECT;

#define getnumdflt(field, name, flt) \
	{ long f; (field) = (cgetnum(buf, (name), &f) == -1) ? (flt) : f; }
#define	getnum(field, name) \
	{ long f; cgetnum(buf, (name), &f); (field) = f; }

	getnumdflt(bsdlp->d_secsize, "se", DEV_BSIZE);
	getnum(bsdlp->d_ntracks, "nt");
	getnum(bsdlp->d_nsectors, "ns");
	getnum(bsdlp->d_ncylinders, "nc");

	if (cgetstr(buf, "dt", &cq) > 0)
		bsdlp->d_type = (unsigned short)gettype(cq, sdtypenames);
	else
		getnumdflt(bsdlp->d_type, "dt", 0);
	getnumdflt(bsdlp->d_secpercyl, "sc", bsdlp->d_nsectors * bsdlp->d_ntracks);
	/* XXX */
	bsdlp->d_secperunith = 0;
	getnumdflt(bsdlp->d_secperunit, "su", bsdlp->d_secpercyl * bsdlp->d_ncylinders);
	getnumdflt(bsdlp->d_bbsize, "bs", BBSIZE);
	getnumdflt(bsdlp->d_sbsize, "sb", SBSIZE);
	strlcpy(psize, "px", sizeof psize);
	strlcpy(pbsize, "bx", sizeof pbsize);
	strlcpy(pfsize, "fx", sizeof pfsize);
	strlcpy(poffset, "ox", sizeof poffset);
	strlcpy(ptype, "tx", sizeof ptype);
	max = 'a' - 1;
	pp = &bsdlp->d_partitions[0];
	bsdlp->d_version = 1;
	for (p = 'a'; p < 'a' + MAXPARTITIONS; p++, pp++) {
		long f;

		psize[1] = pbsize[1] = pfsize[1] = poffset[1] = ptype[1] = p;
		/* XXX */
		if (cgetnum(buf, psize, &f) == -1)
			BSDL_SETPSIZE(pp, 0);
		else {
			uint32_t fsize, frag = 8;

			BSDL_SETPSIZE(pp, f);
			/* XXX */
			pp->p_offseth = 0;
			getnum(pp->p_offset, poffset);
			getnumdflt(fsize, pfsize, 0);
			if (fsize) {
				long bsize;

				if (cgetnum(buf, pbsize, &bsize) == 0)
					frag = bsize / fsize;
				pp->p_fragblock =
				    BSDLABELV1_FFS_FRAGBLOCK(fsize, frag);
			}
			getnumdflt(pp->p_fstype, ptype, 0);
			if (pp->p_fstype == 0 && cgetstr(buf, ptype, &cq) > 0)
				pp->p_fstype = (unsigned char)gettype(cq, fstypenames);
			max = p;
		}
	}
	bsdlp->d_npartitions = max + 1 - 'a';
	(void)strlcpy(psize, "dx", sizeof psize);
	dx = bsdlp->d_drivedata;
	for (p = '0'; p < '0' + NDDATA; p++, dx++) {
		psize[1] = p;
		getnumdflt(*dx, psize, 0);
	}
	bsdlp->d_magic = SDMAGIC;
	bsdlp->d_magic2 = SDMAGIC;
	free(buf);
	return bsdlp;
}

struct disklabel *getdiskbyname(const char *name)
{
	return __BSDL_TC__(__getsdbyname(name));
}

#if defined(__HyperbolaBSD__)
struct bsdlabel *getsdbyname(const char *name)
{
	return __getsdbyname(name);
}
#endif
