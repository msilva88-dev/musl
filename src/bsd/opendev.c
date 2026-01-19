/*
 * Copyright (c) 2000, Todd C. Miller.  All rights reserved.
 * Copyright (c) 1996, Jason Downs.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* opendev from OpenBSD 7.0 source code: lib/libutil/opendev.c */

#define _BSD_SOURCE
#define __USE_MI_MUTEX

#define __NEED_size_t
#define __NEED_uint32_t

#include <bits/alltypes.h>

#include <sys/types.h>
#if defined(__HyperbolaBSD__)
//#include <hyperbk/blkdev.h>
//#include <hyperbk/bdio.h>
#include <hyperbk/disk.h>
#include <hyperbk/dkio.h>
#elif defined(__OpenBSD__)
#include <sys/disk.h>
#include <sys/dkio.h>
#endif
#include <sys/ioctl.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <paths.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <util.h>

#if defined(__HyperbolaBSD__)
#define _PATH_BLKDEVMAP "/dev/diskmap"
//#define _PATH_BLKDEVMAP "/dev/blkdevmap"
#elif defined(__OpenBSD__)
#define _PATH_BLKDEVMAP "/dev/diskmap"
#endif

/*
 * This routine is a generic rewrite of the original code found in
 * bsdlabel(8).
 */
int opendev(const char *path, int oflags, int dflags, char **realpath)
{
	static char namebuf[PATH_MAX];
#if defined(__HyperbolaBSD__)
	struct dk_diskmap bdm;
	//struct bd_blkdevmap bdm;
#elif defined(__OpenBSD__)
	struct dk_diskmap bdm;
#endif
	char *slash, *prefix;
	int fd;

	/* Initial state */
	fd = -1;
	errno = ENOENT;

	if (dflags & OPENDEV_BLCK)
		prefix = "";	/* block device */
	else
		prefix = "r";	/* character device */

	if ((slash = strchr(path, '/'))) {
		strlcpy(namebuf, path, sizeof namebuf);
		fd = open(namebuf, oflags);
	} else if (isduid(path, dflags)) {
		strlcpy(namebuf, path, sizeof namebuf);
		if ((fd = open(_PATH_BLKDEVMAP, oflags)) != -1) {
			bzero(&bdm, sizeof bdm);
			bdm.device = namebuf;
			bdm.fd = fd;
			if (dflags & OPENDEV_PART)
				bdm.flags |= DM_OPENPART;
			if (dflags & OPENDEV_BLCK)
				bdm.flags |= DM_OPENBLCK;

#if defined(__HyperbolaBSD__)
			if (ioctl(fd, DIOCMAP, &bdm) == -1) {
			//if (ioctl(fd, BIOCMAP, &bdm) == -1) {
#elif defined(__OpenBSD__)
			if (ioctl(fd, DIOCMAP, &bdm) == -1) {
#endif
				close(fd);
				fd = -1;
				errno = ENOENT;
			}
		}
	}
	if (!slash && fd == -1 && errno == ENOENT) {
		if (dflags & OPENDEV_PART) {
			/*
			 * First try raw partition (for removable drives)
			 */
			if (snprintf(namebuf, sizeof namebuf, "%s%s%s%c",
			    _PATH_DEV, prefix, path, 'a' + getrawpartition())
			    < sizeof namebuf) {
				fd = open(namebuf, oflags);
			} else
				errno = ENAMETOOLONG;
		}
		if (fd == -1 && errno == ENOENT) {
			if (snprintf(namebuf, sizeof namebuf, "%s%s%s",
			    _PATH_DEV, prefix, path) < sizeof namebuf) {
				fd = open(namebuf, oflags);
			} else
				errno = ENAMETOOLONG;
		}
	}
	if (realpath)
		*realpath = namebuf;

	return fd;
}
