#ifndef _SYS_SWAP_H
#define _SYS_SWAP_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
struct swapent {
	dev_t se_dev;
	int se_flags;
	int se_nblks;
	int se_inuse;
	int se_priority;
	char se_path[PATH_MAX];
};

#define SWAP_ON                 1
#define SWAP_OFF                2
#define SWAP_NSWAP              3
#define SWAP_STATS              4
#define SWAP_CTL                5
#define SWAP_DUMPDEV            7

#define SWF_INUSE               0x1
#define SWF_ENABLE              0x2
#define SWF_BUSY                0x4
#define SWF_FAKE                0x8
#elif defined(__linux__)
#define SWAP_FLAG_PREFER        0x8000
#define SWAP_FLAG_PRIO_MASK     0x7fff
#define SWAP_FLAG_PRIO_SHIFT    0
#define SWAP_FLAG_DISCARD       0x10000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int swapctl(int, const void *, int);
#endif

#if defined(__HyperbolaBSD__) || defined(__linux__)
int swapon (const char *, int);
int swapoff (const char *);
#endif

#ifdef __cplusplus
}
#endif

#endif
