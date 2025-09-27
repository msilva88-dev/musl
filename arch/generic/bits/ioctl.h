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
#define _IOC(a,b,c,d) ( ((a)<<30) | ((b)<<8) | (c) | ((d)<<16) )
#define _IOC_NONE  0U
#define _IOC_WRITE 1U
#define _IOC_READ  2U
#endif

#define _IO(a,b) _IOC(_IOC_NONE,(a),(b),0)
#define _IOW(a,b,c) _IOC(_IOC_WRITE,(a),(b),sizeof(c))
#define _IOR(a,b,c) _IOC(_IOC_READ,(a),(b),sizeof(c))
#define _IOWR(a,b,c) _IOC(_IOC_READ|_IOC_WRITE,(a),(b),sizeof(c))

#if defined(__linux__)
#define TCGETS		0x5401
#define TCSETS		0x5402
#define TCSETSW		0x5403
#define TCSETSF		0x5404
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCGETA	_IOR(0x74, 19, struct termios)
#define TIOCSETA	_IOW(0x74, 20, struct termios)
#define TIOCSETAW	_IOW(0x74, 21, struct termios)
#define TIOCSETAF	_IOW(0x74, 22, struct termios)
#if defined(__HyperbolaBSD__)
#define TCGETA		TIOCGETA
#define TCSETA		TIOCSETA
#define TCSETAW		TIOCSETAW
#define TCSETAF		TIOCSETAF
#define TCSBRK		_IO(0x74, 123)
#endif
#elif defined(__linux__)
#define TCGETA		0x5405
#define TCSETA		0x5406
#define TCSETAW		0x5407
#define TCSETAF		0x5408
#define TCSBRK		0x5409
#endif
#if defined(__linux__)
#define TCXONC		0x540A
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCFLUSH	_IOW(0x74, 16, int)
#if defined(__HyperbolaBSD__)
#define TCFLSH		TIOCFLUSH
#endif
#define TIOCEXCL	_IO(0x74, 13)
#define TIOCNXCL	_IO(0x74, 14)
#define TIOCSCTTY	_IO(0x74, 97)
#define TIOCGPGRP	_IOR(0x74, 119, int)
#define TIOCSPGRP	_IOW(0x74, 118, int)
#define TIOCOUTQ	_IOR(0x74, 115, int)
#elif defined(__linux__)
#define TCFLSH		0x540B
#define TIOCEXCL	0x540C
#define TIOCNXCL	0x540D
#define TIOCSCTTY	0x540E
#define TIOCGPGRP	0x540F
#define TIOCSPGRP	0x5410
#define TIOCOUTQ	0x5411
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSTART	_IO(0x74, 110)
#define TIOCSTOP	_IO(0x74, 111)
#endif
#if defined(__linux__)
#define TIOCSTI		0x5412
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCGWINSZ	_IOR(0x74, 104, struct winsize)
#define TIOCSWINSZ	_IOW(0x74, 103, struct winsize)
#define TIOCMGET	_IOR(0x74, 106, int)
#define TIOCMBIS	_IOW(0x74, 108, int)
#define TIOCMBIC	_IOW(0x74, 107, int)
#define TIOCMSET	_IOW(0x74, 109, int)
#elif defined(__linux__)
#define TIOCGWINSZ	0x5413
#define TIOCSWINSZ	0x5414
#define TIOCMGET	0x5415
#define TIOCMBIS	0x5416
#define TIOCMBIC	0x5417
#define TIOCMSET	0x5418
#endif
#if defined(__linux__)
#define TIOCGSOFTCAR	0x5419
#define TIOCSSOFTCAR	0x541A
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define FIONREAD	_IOR(0x66, 127, int)
#elif defined(__linux__)
#define FIONREAD	0x541B
#endif
#define TIOCINQ		FIONREAD
#if defined(__linux__)
#define TIOCLINUX	0x541C
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCCONS	_IOW(0x74, 98, int)
#elif defined(__linux__)
#define TIOCCONS	0x541D
#endif
#if defined(__linux__)
#define TIOCGSERIAL	0x541E
#define TIOCSSERIAL	0x541F
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCPKT		_IOW(0x74, 112, int)
#define FIONBIO		_IOW(0x66, 126, int)
#define TIOCNOTTY	_IO(0x74, 113)
#define TIOCSETD	_IOW(0x74, 27, int)
#define TIOCGETD	_IOR(0x74, 26, int)
#elif defined(__linux__)
#define TIOCPKT		0x5420
#define FIONBIO		0x5421
#define TIOCNOTTY	0x5422
#define TIOCSETD	0x5423
#define TIOCGETD	0x5424
#endif
#if defined(__linux__)
#define TCSBRKP		0x5425
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSBRK	_IO(0x74, 123)
#define TIOCCBRK	_IO(0x74, 122)
#define TIOCGSID	_IOR(0x74, 99, int)
#elif defined(__linux__)
#define TIOCSBRK	0x5427
#define TIOCCBRK	0x5428
#define TIOCGSID	0x5429
#endif
#if defined(__linux__)
#define TIOCGRS485	0x542E
#define TIOCSRS485	0x542F
#define TIOCGPTN	0x80045430
#define TIOCSPTLCK	0x40045431
#define TIOCGDEV	0x80045432
#define TCGETX		0x5432
#define TCSETX		0x5433
#define TCSETXF		0x5434
#define TCSETXW		0x5435
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TIOCSIG		_IOW(0x74, 95, int)
#elif defined(__linux__)
#define TIOCSIG		0x40045436
#endif
#if defined(__linux__)
#define TIOCVHANGUP	0x5437
#define TIOCGPKT	0x80045438
#define TIOCGPTLCK	0x80045439
#define TIOCGEXCL	0x80045440
#define TIOCGPTPEER	0x5441
#define TIOCGISO7816	0x80285442
#define TIOCSISO7816	0xc0285443
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define FIONCLEX	_IO(0x66, 2)
#define FIOCLEX		_IO(0x66, 1)
#define FIOASYNC	_IOW(0x66, 125, int)
#elif defined(__linux__)
#define FIONCLEX	0x5450
#define FIOCLEX		0x5451
#define FIOASYNC	0x5452
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
#define FIOQSIZE	0x5460
#endif

#define TIOCM_LE        0x001
#define TIOCM_DTR       0x002
#define TIOCM_RTS       0x004
#define TIOCM_ST        0x008
#define TIOCM_SR        0x010
#define TIOCM_CTS       0x020
#define TIOCM_CAR       0x040
#define TIOCM_RNG       0x080
#define TIOCM_DSR       0x100
#define TIOCM_CD        TIOCM_CAR
#define TIOCM_RI        TIOCM_RNG
#if defined(__linux__)
#define TIOCM_OUT1      0x2000
#define TIOCM_OUT2      0x4000
#define TIOCM_LOOP      0x8000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define FIOSETOWN       _IOW(0x66, 124, int)
#define SIOCSPGRP       _IOW(0x73, 8, int)
#define FIOGETOWN       _IOR(0x66, 123, int)
#define SIOCGPGRP       _IOR(0x73, 9, int)
#define SIOCATMARK      _IOR(0x73, 7, int)
#elif defined(__linux__)
#define FIOSETOWN       0x8901
#define SIOCSPGRP       0x8902
#define FIOGETOWN       0x8903
#define SIOCGPGRP       0x8904
#define SIOCATMARK      0x8905
#endif
#if defined(__linux__)
#if __LONG_MAX == 0x7fffffff
#define SIOCGSTAMP      _IOR(0x89, 6, char[16])
#define SIOCGSTAMPNS    _IOR(0x89, 7, char[16])
#else
#define SIOCGSTAMP      0x8906
#define SIOCGSTAMPNS    0x8907
#endif
#endif

#include <bits/ioctl_fix.h>
