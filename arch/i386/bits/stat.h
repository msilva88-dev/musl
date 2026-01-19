/* copied from kernel definition, but with padding replaced
 * by the corresponding correctly-sized userspace types. */

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define __NEED_uint32_t

#include <bits/alltypes.h>
#endif

struct stat {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	mode_t st_mode;
#endif
	dev_t st_dev;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	ino_t st_ino;
#endif
#if defined(__linux__)
	int __st_dev_padding;
	long __st_ino_truncated;
	mode_t st_mode;
#endif
	nlink_t st_nlink;
	uid_t st_uid;
	gid_t st_gid;
	dev_t st_rdev;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if _POSIX_VERSION >= 200809L || defined(_BSD_SOURCE)
	struct timespec st_atim;
	struct timespec st_mtim;
	struct timespec st_ctim;
#else
	time_t st_atime;
	long st_atimensec;
	time_t st_mtime;
	long st_mtimensec;
	time_t st_ctime;
	long st_ctimensec;
#endif
#elif defined(__linux__)
	int __st_rdev_padding;
#endif
	off_t st_size;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	blkcnt_t st_blocks;
	blksize_t st_blksize;
#elif defined(__linux__)
	blksize_t st_blksize;
	blkcnt_t st_blocks;
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	uint32_t st_flags;
	uint32_t st_gen;
#if _POSIX_VERSION >= 200809L || defined(_BSD_SOURCE)
	struct timespec __st_birthtim;
#else
	time_t __st_birthtime;
	long __st_birthtimensec;
#endif
#elif defined(__linux__)
	struct {
		long tv_sec;
		long tv_nsec;
	} __st_atim32, __st_mtim32, __st_ctim32;
	ino_t st_ino;
	struct timespec st_atim;
	struct timespec st_mtim;
	struct timespec st_ctim;
#endif
};
