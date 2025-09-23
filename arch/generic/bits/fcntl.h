#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define O_NONBLOCK       04
#define O_APPEND        010
#define O_SYNC         0200
#define O_DSYNC      O_SYNC
#define O_RSYNC      O_SYNC
#define O_NOFOLLOW     0400
#define O_CREAT       01000
#define O_TRUNC       02000
#define O_EXCL        04000
#define O_NOCTTY    0100000
#define O_CLOEXEC   0200000
#define O_DIRECTORY 0400000
#if defined(__linux__)
#define O_CREAT        0100
#define O_EXCL         0200
#define O_NOCTTY       0400
#define O_TRUNC       01000
#define O_APPEND      02000
#define O_NONBLOCK    04000
#define O_DSYNC      010000
#define O_SYNC     04010000
#define O_RSYNC    04010000
#define O_DIRECTORY 0200000
#define O_NOFOLLOW  0400000
#define O_CLOEXEC  02000000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define O_SHLOCK        020
#define O_EXLOCK        040
#define O_ASYNC        0100
#define O_FSYNC      O_SYNC
#define O_NDELAY O_NONBLOCK
#elif defined(__linux__)
#define O_ASYNC      020000
#define O_DIRECT     040000
#define O_LARGEFILE 0100000
#define O_NOATIME  01000000
#define O_PATH    010000000
#define O_TMPFILE 020200000
#define O_NDELAY O_NONBLOCK
#endif

#define F_DUPFD  0
#define F_GETFD  1
#define F_SETFD  2
#define F_GETFL  3
#define F_SETFL  4

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define F_GETOWN 5
#define F_SETOWN 6
#elif defined(__linux__)
#define F_SETOWN 8
#define F_GETOWN 9
#define F_SETSIG 10
#define F_GETSIG 11
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define F_GETLK 7
#define F_SETLK 8
#define F_SETLKW 9
#elif defined(__linux__)
#if __LONG_MAX == 0x7fffffffL
#define F_GETLK 12
#define F_SETLK 13
#define F_SETLKW 14
#else
#define F_GETLK 5
#define F_SETLK 6
#define F_SETLKW 7
#endif
#endif

#if defined(__linux__)
#define F_SETOWN_EX 15
#define F_GETOWN_EX 16

#define F_GETOWNER_UIDS 17
#endif
