#if defined(__HyperbolaBSD__)
#define __NEED_int64_t
#define __NEED_uint32_t
#define __NEED_uint64_t

#include <bits/alltypes.h>

#define MFSNAMELEN 16
#define MNAMELEN 90
#endif

struct statfs {
#if defined(__HyperbolaBSD__)
	uint32_t f_flags, f_bsize, f_iosize;
	uint64_t f_blocks, f_bfree;
	int64_t f_bavail;
	uint64_t f_files, f_ffree;
	int64_t f_favail;
	uint64_t f_syncwrites, f_syncreads, f_asyncwrites, f_asyncreads;
#elif defined(__linux__)
	unsigned f_type, f_bsize;
	fsblkcnt_t f_blocks, f_bfree, f_bavail;
	fsfilcnt_t f_files, f_ffree;
#endif
	fsid_t f_fsid;
#if defined(__HyperbolaBSD__)
	uint32_t f_namemax;
	uid_t f_owner;
	uint64_t f_ctime;
	char f_fstypename[MFSNAMELEN], f_mntonname[MNAMELEN];
	char f_mntfromname[MNAMELEN], f_mntfromspec[MNAMELEN];
	union mount_info mount_info;
#elif defined(__linux__)
	unsigned f_namelen, f_frsize, f_flags, f_spare[4];
#endif
};
