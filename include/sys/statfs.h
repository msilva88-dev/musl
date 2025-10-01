#ifndef	_SYS_STATFS_H
#define	_SYS_STATFS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#include <sys/statvfs.h>

typedef struct __fsid_t {
	int __val[2];
} fsid_t;

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/mount_info.h>
#endif
#include <bits/statfs.h>

int statfs (const char *, struct statfs *);
int fstatfs (int, struct statfs *);

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
int getfsstat(struct statfs *, size_t, int);
int getmntinfo(struct statfs **, int);
#endif
#endif

#if defined(_LARGEFILE64_SOURCE)
#define statfs64 statfs
#define fstatfs64 fstatfs
#define fsblkcnt64_t fsblkcnt_t
#define fsfilcnt64_t fsfilcnt_t
#endif

#ifdef __cplusplus
}
#endif

#endif
