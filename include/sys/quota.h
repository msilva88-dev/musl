#ifndef _SYS_QUOTA_H
#define _SYS_QUOTA_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__linux__)
#include <stdint.h>

#define _LINUX_QUOTA_VERSION 2
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if !defined(dbtob)
#define dbtob(num) ((num) << 9)
#define btodb(num) ((num) >> 9)
#endif
#elif defined(__linux__)
#define dbtob(num) ((num) << 10)
#define btodb(num) ((num) >> 10)
#endif
#if defined(__linux__)
#define fs_to_dq_blocks(num, blksize) (((num) * (blksize)) / 1024)
#endif

#define MAX_IQ_TIME 604800
#define MAX_DQ_TIME 604800

#define MAXQUOTAS 2
#define USRQUOTA  0
#define GRPQUOTA  1

#define INITQFNAMES { "user", "group", "undefined" };

#define QUOTAFILENAME "quota"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define QUOTAGROUP "operator"
#elif defined(__linux__)
#define QUOTAGROUP "staff"
#endif

#if defined(__linux__)
#define NR_DQHASH 43
#define NR_DQUOTS 256
#endif

#define SUBCMDMASK       0x00ff
#define SUBCMDSHIFT      8
#define QCMD(cmd, type)  (((cmd) << SUBCMDSHIFT) | ((type) & SUBCMDMASK))

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define Q_QUOTAON  0x000100
#define Q_QUOTAOFF 0x000200
#define Q_GETQUOTA 0x000300
#define Q_SETQUOTA 0x000400
#define Q_SETUSE   0x000500 // bsd-only
#define Q_SYNC     0x000600
#elif defined(__linux__)
#define Q_SYNC     0x800001
#define Q_QUOTAON  0x800002
#define Q_QUOTAOFF 0x800003
// Q_GETFMT, Q_GETINFO, Q_SETINFO are Linux only
#define Q_GETFMT   0x800004
#define Q_GETINFO  0x800005
#define Q_SETINFO  0x800006
#define Q_GETQUOTA 0x800007
#define Q_SETQUOTA 0x800008
#endif

#if defined(__linux__)
#define	QFMT_VFS_OLD 1
#define	QFMT_VFS_V0 2
#define QFMT_OCFS2 3
#define	QFMT_VFS_V1 4

#define QIF_BLIMITS	1
#define QIF_SPACE	2
#define QIF_ILIMITS	4
#define QIF_INODES	8
#define QIF_BTIME	16
#define QIF_ITIME	32
#define QIF_LIMITS	(QIF_BLIMITS | QIF_ILIMITS)
#define QIF_USAGE	(QIF_SPACE | QIF_INODES)
#define QIF_TIMES	(QIF_BTIME | QIF_ITIME)
#define QIF_ALL		(QIF_LIMITS | QIF_USAGE | QIF_TIMES)
#endif

struct dqblk {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	uint32_t dqb_bhardlimit;
	uint32_t dqb_bsoftlimit;
	uint32_t dqb_curblocks;
	uint32_t dqb_ihardlimit;
	uint32_t dqb_isoftlimit;
	uint32_t dqb_curinodes;
	uint32_t dqb_btime;
	uint32_t dqb_itime;
#elif defined(__linux__)
	uint64_t dqb_bhardlimit;
	uint64_t dqb_bsoftlimit;
	uint64_t dqb_curspace;
	uint64_t dqb_ihardlimit;
	uint64_t dqb_isoftlimit;
	uint64_t dqb_curinodes;
	uint64_t dqb_btime;
	uint64_t dqb_itime;
	uint32_t dqb_valid;
#endif
};

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(dq_bhardlimit)
#undef	dq_bhardlimit
#undef	dq_bsoftlimit
#undef	dq_curblocks
#undef	dq_ihardlimit
#undef	dq_isoftlimit
#undef	dq_curinodes
#undef	dq_btime
#undef	dq_itime
#endif
#endif
#define	dq_bhardlimit	dq_dqb.dqb_bhardlimit
#define	dq_bsoftlimit	dq_dqb.dqb_bsoftlimit
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define	dq_curblocks	dq_dqb.dqb_curblocks
#elif defined(__linux__)
#define	dq_curspace	dq_dqb.dqb_curspace
#define	dq_valid	dq_dqb.dqb_valid
#endif
#define	dq_ihardlimit	dq_dqb.dqb_ihardlimit
#define	dq_isoftlimit	dq_dqb.dqb_isoftlimit
#define	dq_curinodes	dq_dqb.dqb_curinodes
#define	dq_btime	dq_dqb.dqb_btime
#define	dq_itime	dq_dqb.dqb_itime

#if defined(__linux__)
#define dqoff(UID)      ((long long)(UID) * sizeof (struct dqblk))

#define IIF_BGRACE	1
#define IIF_IGRACE	2
#define IIF_FLAGS	4
#define IIF_ALL		(IIF_BGRACE | IIF_IGRACE | IIF_FLAGS)

struct dqinfo {
	uint64_t dqi_bgrace;
	uint64_t dqi_igrace;
	uint32_t dqi_flags;
	uint32_t dqi_valid;
};
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int quotactl(const char *, int, int, char *);
#elif defined(__linux__)
int quotactl(int, const char *, int, char *);
#endif

#ifdef __cplusplus
}
#endif

#endif
