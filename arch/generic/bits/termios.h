struct termios {
	tcflag_t c_iflag;
	tcflag_t c_oflag;
	tcflag_t c_cflag;
	tcflag_t c_lflag;
#if defined(__linux__)
	cc_t c_line;
#endif
	cc_t c_cc[NCCS];
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int c_ispeed;
	int c_ospeed;
#elif defined(__linux__)
	speed_t __c_ispeed;
	speed_t __c_ospeed;
#endif
};

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define VINTR     8
#define VQUIT     9
#define VERASE    3
#define VKILL     5
#define VEOF      0
#define VTIME    17
#define VMIN     16
#elif defined(__linux__)
#define VINTR     0
#define VQUIT     1
#define VERASE    2
#define VKILL     3
#define VEOF      4
#define VTIME     5
#define VMIN      6
#endif
#if defined(__linux__)
#define VSWTC     7
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define VSTART   12
#define VSTOP    13
#elif defined(__linux__)
#define VSTART    8
#define VSTOP     9
#endif
#define VSUSP    10
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define VEOL      1
#define VREPRINT  6
#define VDISCARD 15
#define VWERASE   4
#define VLNEXT   14
#define VEOL2     2
#elif defined(__linux__)
#define VEOL     11
#define VREPRINT 12
#define VDISCARD 13
#define VWERASE  14
#define VLNEXT   15
#define VEOL2    16
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define VDSUSP   11
#define VSTATUS  18
#endif
#endif

#define IGNBRK  0000001
#define BRKINT  0000002
#define IGNPAR  0000004
#define PARMRK  0000010
#define INPCK   0000020
#define ISTRIP  0000040
#define INLCR   0000100
#define IGNCR   0000200
#define ICRNL   0000400
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define IUCLC   0010000
#define IXON    0001000
#elif defined(__linux__)
#define IUCLC   0001000
#define IXON    0002000
#endif
#define IXANY   0004000
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define IXOFF   0002000
#elif defined(__linux__)
#define IXOFF   0010000
#endif
#define IMAXBEL 0020000
#if defined(__linux__)
#define IUTF8   0040000
#endif

#define OPOST  0000001
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define OLCUC  0000040
#define ONLCR  0000002
#define OCRNL  0000020
#define ONOCR  0000100
#define ONLRET 0000200
#elif defined(__linux__)
#define OLCUC  0000002
#define ONLCR  0000004
#define OCRNL  0000010
#define ONOCR  0000020
#define ONLRET 0000040
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define OXTABS 0000004
#define ONOEOT 0000010
#endif
#elif defined(__linux__)
#define OFILL  0000100
#define OFDEL  0000200
#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE) || defined(_XOPEN_SOURCE)
#define NLDLY  0000400
#define NL0    0000000
#define NL1    0000400
#define CRDLY  0003000
#define CR0    0000000
#define CR1    0001000
#define CR2    0002000
#define CR3    0003000
#define TABDLY 0014000
#define TAB0   0000000
#define TAB1   0004000
#define TAB2   0010000
#define TAB3   0014000
#define BSDLY  0020000
#define BS0    0000000
#define BS1    0020000
#define FFDLY  0100000
#define FF0    0000000
#define FF1    0100000
#endif
#endif

#if defined(__linux__)
#define VTDLY  0040000
#define VT0    0000000
#define VT1    0040000
#endif

#define B0       0000000
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define B50      0000062
#define B75      0000113
#define B110     0000156
#define B134     0000206
#define B150     0000226
#define B200     0000310
#define B300     0000454
#define B600     0001130
#define B1200    0002260
#define B1800    0003410
#define B2400    0004540
#define B4800    0011300
#ifdef _BSD_SOURCE
#define B7200    0016040
#endif
#define B9600    0022600
#ifdef _BSD_SOURCE
#define B14400   0034100
#endif
#define B19200   0045400
#ifdef _BSD_SOURCE
#define B28800   0070200
#endif
#define B38400   0113000
#elif defined(__linux__)
#define B50      0000001
#define B75      0000002
#define B110     0000003
#define B134     0000004
#define B150     0000005
#define B200     0000006
#define B300     0000007
#define B600     0000010
#define B1200    0000011
#define B1800    0000012
#define B2400    0000013
#define B4800    0000014
#define B9600    0000015
#define B19200   0000016
#define B38400   0000017
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define B57600   0160400
#ifdef _BSD_SOURCE
#define B76800   0226000
#endif
#define B115200  0341000
#define B230400  0702000
#elif defined(__linux__)
#define B57600   0010001
#define B115200  0010002
#define B230400  0010003
#endif
#if defined(__linux__)
#define B460800  0010004
#define B500000  0010005
#define B576000  0010006
#define B921600  0010007
#define B1000000 0010010
#define B1152000 0010011
#define B1500000 0010012
#define B2000000 0010013
#define B2500000 0010014
#define B3000000 0010015
#define B3500000 0010016
#define B4000000 0010017
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define CSIZE  0001400
#elif defined(__linux__)
#define CSIZE  0000060
#endif
#define CS5    0000000
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define CS6    0000400
#define CS7    0001000
#define CS8    0001400
#define CSTOPB 0002000
#define CREAD  0004000
#define PARENB 0010000
#define PARODD 0020000
#define HUPCL  0040000
#define CLOCAL 0100000
#elif defined(__linux__)
#define CS6    0000020
#define CS7    0000040
#define CS8    0000060
#define CSTOPB 0000100
#define CREAD  0000200
#define PARENB 0000400
#define PARODD 0001000
#define HUPCL  0002000
#define CLOCAL 0004000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define ISIG   0000200
#define ICANON 0000400
#elif defined(__linux__)
#define ISIG   0000001
#define ICANON 0000002
#endif
#define ECHO   0000010
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define ECHOE  0000002
#define ECHOK  0000004
#define ECHONL 0000020
#define NOFLSH 020000000000
#define TOSTOP 000020000000
#define IEXTEN 0002000
#elif defined(__linux__)
#define ECHOE  0000020
#define ECHOK  0000040
#define ECHONL 0000100
#define NOFLSH 0000200
#define TOSTOP 0000400
#define IEXTEN 0100000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TCOOFF 1
#define TCOON  2
#define TCIOFF 3
#define TCION  4
#elif defined(__linux__)
#define TCOOFF 0
#define TCOON  1
#define TCIOFF 2
#define TCION  3
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TCIFLUSH  1
#define TCOFLUSH  2
#define TCIOFLUSH 3
#elif defined(__linux__)
#define TCIFLUSH  0
#define TCOFLUSH  1
#define TCIOFLUSH 2
#endif

#define TCSANOW   0
#define TCSADRAIN 1
#define TCSAFLUSH 2
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define TCSASOFT  16
#endif
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define EXTA    0045400
#define EXTB    0113000
#elif defined(__linux__)
#define EXTA    0000016
#define EXTB    0000017
#endif
#if defined(__linux__)
#define CBAUD   0010017
#define CBAUDEX 0010000
#define CIBAUD  002003600000
#define CMSPAR  010000000000
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define CRTSCTS 0200000
#elif defined(__linux__)
#define CRTSCTS 020000000000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define XCASE   00100000000
#define ECHOCTL 0000100
#define ECHOPRT 0000040
#define ECHOKE  0000001
#define FLUSHO  00040000000
#define PENDIN  04000000000
#define EXTPROC 0004000
#elif defined(__linux__)
#define XCASE   0000004
#define ECHOCTL 0001000
#define ECHOPRT 0002000
#define ECHOKE  0004000
#define FLUSHO  0010000
#define PENDIN  0040000
#define EXTPROC 0200000
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define ALTWERASE  0000001000
#define NOKERNINFO 0200000000
#endif
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define CIGNORE    00000001
#define CRTS_IFLOW CRTSCTS
#define CCTS_OFLOW CRTSCTS
#define MDMBUF     04000000
#define CHWFLOW    (MDMBUF|CRTSCTS)
#endif
#elif defined(__linux__)
#define XTABS  0014000
#endif
#endif // defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
