#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <bits/alltypes.h>
#include <bits/termios.h>
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _IOC(a,b,c,d) ( (a) | ((b)<<8) | (c) | (((d)&0x1FFF)<<16) )
#define _IOC_NONE  0x20000000UL
#define _IOC_WRITE 0x80000000UL
#define _IOC_READ  0x40000000UL
#elif defined(__linux__)
#define _IOC(a,b,c,d) ( ((a)<<29) | ((b)<<8) | (c) | ((d)<<16) )
#define _IOC_NONE  1U
#define _IOC_WRITE 4U
#define _IOC_READ  2U
#endif

#define _IO(a,b) _IOC(_IOC_NONE,(a),(b),0)
#define _IOW(a,b,c) _IOC(_IOC_WRITE,(a),(b),sizeof(c))
#define _IOR(a,b,c) _IOC(_IOC_READ,(a),(b),sizeof(c))
#define _IOWR(a,b,c) _IOC(_IOC_READ|_IOC_WRITE,(a),(b),sizeof(c))

#define FIONCLEX	_IO('f', 2)
#define FIOCLEX		_IO('f', 1)
#define FIOASYNC	_IOW('f', 125, int)
#define FIONBIO		_IOW('f', 126, int)
#define FIONREAD	_IOR('f', 127, int)
#define TIOCINQ		FIONREAD
#if defined(__linux__)
#define FIOQSIZE	_IOR('f', 128, char[8])
#define TIOCGETP	_IOR('t', 8, char[6])
#define TIOCSETP	_IOW('t', 9, char[6])
#define TIOCSETN	_IOW('t', 10, char[6])
#endif

#if defined(__linux__)
#define TIOCSETC	_IOW('t', 17, char[6])
#define TIOCGETC	_IOR('t', 18, char[6])
#define TCGETS		_IOR('t', 19, char[44])
#define TCSETS		_IOW('t', 20, char[44])
#define TCSETSW		_IOW('t', 21, char[44])
#define TCSETSF		_IOW('t', 22, char[44])
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCGETA	_IOR('t', 19, struct termios)
#define TIOCSETA	_IOW('t', 20, struct termios)
#define TIOCSETAW	_IOW('t', 21, struct termios)
#define TIOCSETAF	_IOW('t', 22, struct termios)
#if defined(__HyperbolaBSD__)
#define TCGETS		TIOCGETA
#define TCSETS		TIOCSETA
#define TCSETSW		TIOCSETAW
#define TCSETSF		TIOCSETAF
#define TCGETA		TIOCGETA
#define TCSETA		TIOCSETA
#define TCSETAW		TIOCSETAW
#define TCSETAF		TIOCSETAF
#endif
#elif defined(__linux__)
#define TCGETA		_IOR('t', 23, char[20])
#define TCSETA		_IOW('t', 24, char[20])
#define TCSETAW		_IOW('t', 25, char[20])
#define TCSETAF		_IOW('t', 28, char[20])
#endif

#if defined(__linux__)
#define TCSBRK		_IO('t', 29)
#define TCXONC		_IO('t', 30)
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCFLUSH	_IOW('t', 16, int)
#if defined(__HyperbolaBSD__)
#define TCFLSH		TIOCFLUSH
#endif
#elif defined(__linux__)
#define TCFLSH		_IO('t', 31)
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSWINSZ	_IOW('t', 103, struct winsize)
#define TIOCGWINSZ	_IOR('t', 104, struct winsize)
#elif defined(__linux__)
#define TIOCSWINSZ	_IOW('t', 103, char[8])
#define TIOCGWINSZ	_IOR('t', 104, char[8])
#endif
#define TIOCSTART	_IO('t', 110)
#define TIOCSTOP	_IO('t', 111)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCEXT		_IOW('t', 96, int)
#endif

#define TIOCOUTQ	_IOR('t', 115, int)

#elif defined(__linux__)
#define TIOCGLTC	_IOR('t', 116, char[6])
#define TIOCSLTC	_IOW('t', 117, char[6])
#endif
#define TIOCSPGRP	_IOW('t', 118, int)
#define TIOCGPGRP	_IOR('t', 119, int)

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCEXCL	_IO('t', 13)
#define TIOCNXCL	_IO('t', 14)
#define TIOCSCTTY	_IO('t', 97)
#elif defined(__linux__)
#define TIOCEXCL	0x540C
#define TIOCNXCL	0x540D
#define TIOCSCTTY	0x540E
#endif

#if defined(__linux__)
#define TIOCSTI		0x5412
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCMGET	_IOR('t', 106, int)
#define TIOCMBIS	_IOW('t', 108, int)
#define TIOCMBIC	_IOW('t', 107, int)
#define TIOCMSET	_IOW('t', 109, int)
#if defined(__OpenBSD__)
#define TIOCMODG	TIOCMGET
#define TIOCMODS	TIOCMSET
#endif
#elif defined(__linux__)
#define TIOCMGET	0x5415
#define TIOCMBIS	0x5416
#define TIOCMBIC	0x5417
#define TIOCMSET	0x5418
#endif
#define TIOCM_LE	0x001
#define TIOCM_DTR	0x002
#define TIOCM_RTS	0x004
#define TIOCM_ST	0x008
#define TIOCM_SR	0x010
#define TIOCM_CTS	0x020
#define TIOCM_CAR	0x040
#define TIOCM_RNG	0x080
#define TIOCM_DSR	0x100
#define TIOCM_CD	TIOCM_CAR
#define TIOCM_RI	TIOCM_RNG
#if defined(__linux__)
#define TIOCM_OUT1	0x2000
#define TIOCM_OUT2	0x4000
#define TIOCM_LOOP	0x8000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCUCNTL	_IOW('t', 102, int)
#elif defined(__linux__)
#define TIOCGSOFTCAR	0x5419
#define TIOCSSOFTCAR	0x541A
#define TIOCLINUX	0x541C
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCCONS	_IOW('t', 98, int)
#elif defined(__linux__)
#define TIOCCONS	0x541D
#endif
#if defined(__linux__)
#define TIOCGSERIAL	0x541E
#define TIOCSSERIAL	0x541F
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCPKT	_IOW('t', 112, int)
#elif defined(__linux__)
#define TIOCPKT	0x5420
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCNOTTY	_IO('t', 113)
#define TIOCSETD	_IOW('t', 27, int)
#define TIOCGETD	_IOR('t', 26, int)
#elif defined(__linux__)
#define TIOCNOTTY	0x5422
#define TIOCSETD	0x5423
#define TIOCGETD	0x5424
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCCHKVERAUTH	_IO('t', 30)
#define TIOCCLRVERAUTH	_IO('t', 29)
#define TIOCSETVERAUTH	_IOW('t', 28, int)
#elif defined(__linux__)
#define TCSBRKP		0x5425
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSBRK	_IO('t', 123)
#define TIOCCBRK	_IO('t', 122)
#define TIOCGSID	_IOR('t', 99, int)
#elif defined(__linux__)
#define TIOCSBRK	0x5427
#define TIOCCBRK	0x5428
#define TIOCGSID	0x5429
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCCDTR	_IO('t', 120)
#define TIOCSDTR	_IO('t', 121)
#define TIOCUCNTL_SBRK	(TIOCSBRK & 0377)
#define TIOCUCNTL_CBRK	(TIOCCBRK & 0377)
#define UIOCCMD(n)	_IO('u', n)
#elif defined(__linux__)
#define TIOCGRS485	0x542e
#define TIOCSRS485	0x542f
#define TIOCGPTN	_IOR('T',0x30, unsigned int)
#define TIOCSPTLCK	_IOW('T',0x31, int)
#define TIOCGDEV	_IOR('T',0x32, unsigned int)
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSIG		_IOW('t', 95, int)
#elif defined(__linux__)
#define TIOCSIG		_IOW('T',0x36, int)
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCDRAIN	_IO('t', 94)
#define TIOCGFLAGS	_IOR('t', 93, int)
#define TIOCSFLAGS	_IOW('t', 92, int)
#define TIOCGTSTAMP	_IOR('t', 91, struct timeval)
#define TIOCSTSTAMP	_IOW('t', 90, struct tstamps)
#elif defined(__linux__)
#define TIOCVHANGUP	0x5437
#define TIOCGPKT	_IOR('T', 0x38, int)
#define TIOCGPTLCK	_IOR('T', 0x39, int)
#define TIOCGEXCL	_IOR('T', 0x40, int)
#define TIOCGPTPEER	_IO('T', 0x41)
#endif

#if defined(__linux__)
#define TIOCSERCONFIG	0x5453
#define TIOCSERGWILD	0x5454
#define TIOCSERSWILD	0x5455
#define TIOCGLCKTRMIOS	0x5456
#define TIOCSLCKTRMIOS	0x5457
#define TIOCSERGSTRUCT	0x5458
#define TIOCSERGETLSR	0x5459
#define TIOCSERGETMULTI	0x545A
#define TIOCSERSETMULTI	0x545B
#endif

#if defined(__linux__)
#define TIOCMIWAIT	0x545C
#define TIOCGICOUNT	0x545D
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define FIOSETOWN       _IOW('f', 124, int)
#define SIOCSPGRP       _IOW('s', 8, int)
#define FIOGETOWN       _IOR('f', 123, int)
#define SIOCGPGRP       _IOR('s', 9, int)
#define SIOCATMARK      _IOR('s', 7, int)
#elif defined(__linux__)
#define FIOSETOWN       0x8901
#define SIOCSPGRP       0x8902
#define FIOGETOWN       0x8903
#define SIOCGPGRP       0x8904
#define SIOCATMARK      0x8905
#endif
#if defined(__linux__)
#define SIOCGSTAMP      0x8906
#define SIOCGSTAMPNS    0x8907
#endif
