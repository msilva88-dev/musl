#if defined(__linux__)
#undef NCCS
#define NCCS 19
#endif
struct termios {
	tcflag_t c_iflag;
	tcflag_t c_oflag;
	tcflag_t c_cflag;
	tcflag_t c_lflag;
	cc_t c_cc[NCCS];
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int c_ispeed;
	int c_ospeed;
#elif defined(__linux__)
	cc_t c_line;
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
#define VMIN     16
#define VEOL      1
#define VTIME    17
#define VEOL2     2
#elif defined(__linux__)
#define VINTR     0
#define VQUIT     1
#define VERASE    2
#define VKILL     3
#define VEOF      4
#define VMIN      5
#define VEOL      6
#define VTIME     7
#define VEOL2     8
#endif
#if defined(__linux__)
#define VSWTC     9
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define VWERASE   4
#define VREPRINT  6
#define VSUSP    10
#define VSTART   12
#define VSTOP    13
#define VLNEXT   14
#define VDISCARD 15
#elif defined(__linux__)
#define VWERASE  10
#define VREPRINT 11
#define VSUSP    12
#define VSTART   13
#define VSTOP    14
#define VLNEXT   15
#define VDISCARD 16
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
#define IXON    0001000
#define IXOFF   0002000
#define IXANY   0004000
#define IUCLC   0010000
#define IMAXBEL 0020000
#if defined(__linux__)
#define IUTF8   0040000
#endif

#define OPOST  0000001
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define ONLCR  0000002
#define OLCUC  0000040
#define OCRNL  0000020
#define ONOCR  0000100
#define ONLRET 0000200
#elif defined(__linux__)
#define ONLCR  0000002
#define OLCUC  0000004
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
#define NLDLY  0001400
#define NL0    0000000
#define NL1    0000400
#define NL2    0001000
#define NL3    0001400
#define TABDLY 0006000
#define TAB0   0000000
#define TAB1   0002000
#define TAB2   0004000
#define TAB3   0006000
#define CRDLY  0030000
#define CR0    0000000
#define CR1    0010000
#define CR2    0020000
#define CR3    0030000
#define FFDLY  0040000
#define FF0    0000000
#define FF1    0040000
#define BSDLY  0100000
#define BS0    0000000
#define BS1    0100000
#endif
#endif

#if defined(__linux__)
#define VTDLY  0200000
#define VT0    0000000
#define VT1    0200000
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
#define B57600   00020
#define B115200  00021
#define B230400  00022
#endif
#if defined(__linux__)
#define B460800  00023
#define B500000  00024
#define B576000  00025
#define B921600  00026
#define B1000000 00027
#define B1152000 00030
#define B1500000 00031
#define B2000000 00032
#define B2500000 00033
#define B3000000 00034
#define B3500000 00035
#define B4000000 00036
#endif

#define CSIZE  00001400
#define CS5    00000000
#define CS6    00000400
#define CS7    00001000
#define CS8    00001400
#define CSTOPB 00002000
#define CREAD  00004000
#define PARENB 00010000
#define PARODD 00020000
#define HUPCL  00040000
#define CLOCAL 00100000

#define ECHOE   0x00000002
#define ECHOK   0x00000004
#define ECHO    0x00000008
#define ECHONL  0x00000010
#define ISIG    0x00000080
#define ICANON  0x00000100
#define IEXTEN  0x00000400
#define TOSTOP  0x00400000
#define NOFLSH  0x80000000

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
#define CBAUD   00377
#define CBAUDEX 0000020
#define CIBAUD  077600000
#define CMSPAR  010000000000
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define CRTSCTS 0200000
#elif defined(__linux__)
#define CRTSCTS 020000000000
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define XCASE   0x01000000
#elif defined(__linux__)
#define XCASE   0x00004000
#endif
#define ECHOCTL 0x00000040
#define ECHOPRT 0x00000020
#define ECHOKE  0x00000001
#define FLUSHO  0x00800000
#define PENDIN  0x20000000
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define EXTPROC 0x00000800
#elif defined(__linux__)
#define EXTPROC 0x10000000
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define ALTWERASE  0x00000200
#define NOKERNINFO 0x02000000
#endif
#endif

#if defined(__HyperbolaBSD__) && defined(__OpenBSD__)
#ifdef _BSD_SOURCE
#define CIGNORE    00000001
#define CRTS_IFLOW CRTSCTS
#define CCTS_OFLOW CRTSCTS
#define MDMBUF     04000000
#define CHWFLOW    (MDMBUF|CRTSCTS)
#endif
#elif defined(__linux__)
#define XTABS   00006000
#define TIOCSER_TEMT 1
#endif
#endif // defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
