/*
 * Copyright (c) 1989, 1991, 1993
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
 *
 *      @(#)mount.h     8.15 (Berkeley) 7/14/94
 */

/* mount_info from OpenBSD 7.0 source code: sys/sys/mount.h */

#ifndef _SYS_MOUNT_INFO_H
#define _SYS_MOUNT_INFO_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/socket.h>

#define MOUNT_AFS "afs"
#if defined(__HyperbolaBSD__)
#define MOUNT_EXT2 "ext2"
#define MOUNT_ISO9660 "iso9660"
#define MOUNT_EXT2FS MOUNT_EXT2
#define MOUNT_CD9660 MOUNT_ISO9660
#elif defined(__OpenBSD__)
#define MOUNT_CD9660 "cd9660"
#define MOUNT_EXT2FS "ext2fs"
#endif
#define MOUNT_FFS "ffs"
#if defined(__HyperbolaBSD__)
#define MOUNT_FUSE "fuse"
#define MOUNT_FUSEFS MOUNT_FUSE
#elif defined(__OpenBSD__)
#define MOUNT_FUSEFS "fuse"
#endif
#define MOUNT_MFS "mfs"
#if defined(__HyperbolaBSD__)
#define MOUNT_FAT "fat"
#define MOUNT_MSDOS MOUNT_FAT
#elif defined(__OpenBSD__)
#define MOUNT_MSDOS "msdos"
#endif
#define MOUNT_NCPFS "ncpfs"
#define MOUNT_NFS "nfs"
#define MOUNT_NTFS "ntfs"
#define MOUNT_TMPFS "tmpfs"
#define MOUNT_UDF "udf"
#define MOUNT_UFS MOUNT_FFS

struct export_args {
	int ex_flags;
	uid_t ex_root;
	struct xucred ex_anon;
	struct sockaddr *ex_addr;
	int ex_addrlen;
	struct sockaddr *ex_mask;
	int ex_masklen;
};

#define MOUNT_INFO_ARGS \
	char *fspec; \
	struct export_args export_info;

#define MOUNT_MODE_ARGS(name) \
	uid_t uid; \
	gid_t gid; \
	mode_t name;

struct iso_args {
	MOUNT_INFO_ARGS
	int flags, sess;
};

enum {
	ISOFSMNT_NORRIP = 001,
	ISOFSMNT_GENS = 002,
	ISOFSMNT_EXTATT = 004,
	ISOFSMNT_NOJOLIET = 010,
	ISOFSMNT_SESS = 020
};

struct mfs_args {
	MOUNT_INFO_ARGS
	caddr_t base;
	unsigned long size;
};

struct msdosfs_args {
	MOUNT_INFO_ARGS
	MOUNT_MODE_ARGS(mask)
	int flags;
};

#if defined(__HyperbolaBSD__)
enum { FATMNT_SHORTNAME = 1, FATMNT_LONGNAME, FATMNT_NOWIN95 };
#endif
enum { MSDOSFSMNT_SHORTNAME = 1, MSDOSFSMNT_LONGNAME, MSDOSFSMNT_NOWIN95 };

struct ntfs_args {
	MOUNT_INFO_ARGS
	MOUNT_MODE_ARGS(mode)
	unsigned long flag;
};

enum { NTFS_MFLAG_CASEINS = 1, NTFS_MFLAG_ALLNAMES };

struct nfs_args {
	int version;
	struct sockaddr *addr;
	int addrlen, sotype, proto;
	unsigned char *fh;
	int fhsize, flags, wsize, rsize, readdirsize, timeo, retrans;
	int maxgrouplist, readahead, leaseterm, deadthresh;
	char *hostname;
	int acregmin, acregmax, acdirmin, acdirmax;
};

#define NFS_ARGSVERSION 4

enum {
	// mount flags
	NFSMNT_RESVPORT		= 0x000000,
	NFSMNT_SOFT		= 0x000001,
	NFSMNT_WSIZE		= 0x000002,
	NFSMNT_RSIZE		= 0x000004,
	NFSMNT_TIMEO		= 0x000008,
	NFSMNT_RETRANS		= 0x000010,
	NFSMNT_MAXGRPS		= 0x000020,
	NFSMNT_INT		= 0x000040,
	NFSMNT_NOCONN		= 0x000080,
	NFSMNT_NQNFS		= 0x000100,
	NFSMNT_NFSV3		= 0x000200,
	NFSMNT_KERB		= 0x000400,
	NFSMNT_DUMBTIMR		= 0x000800,
	NFSMNT_LEASETERM	= 0x001000,
	NFSMNT_READAHEAD	= 0x002000,
	NFSMNT_DEADTHRESH	= 0x004000,
	NFSMNT_NOAC		= 0x008000,
	NFSMNT_RDIRPLUS		= 0x010000,
	NFSMNT_READDIRSIZE	= 0x020000,
	// syscall flags
	NFSMNT_ACREGMIN		= 0x040000,
	NFSMNT_ACREGMAX		= 0x080000,
	NFSMNT_ACDIRMIN		= 0x100000,
	NFSMNT_ACDIRMAX		= 0x200000
};

struct tmpfs_args {
	int ta_version;
	ino_t ta_nodes_max;
	off_t ta_size_max;
	uid_t ta_root_uid;
	gid_t ta_root_gid;
	mode_t ta_root_mode;
};

#define TMPFS_ARGS_VERSION 1

struct ufs_args { MOUNT_INFO_ARGS };

union mount_info {
	struct iso_args iso_args;
	struct mfs_args mfs_args;
	struct msdosfs_args msdosfs_args;
	struct ntfs_args ntfs_args;
	struct nfs_args nfs_args;
	struct tmpfs_args tmpfs_args;
	struct ufs_args ufs_args;
} _Alignas(160);

#ifdef __cplusplus
}
#endif

#endif
