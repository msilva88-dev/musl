#define EPERM            1
#define ENOENT           2
#define ESRCH            3
#define EINTR            4
#define EIO              5
#define ENXIO            6
#define E2BIG            7
#define ENOEXEC          8
#define EBADF            9
#define ECHILD          10
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define EDEADLK         11 // 35 linux
#elif defined(__linux__)
#define EAGAIN          11
#endif
#define ENOMEM          12
#define EACCES          13
#define EFAULT          14
#if defined(__linux__) || defined(_BSD_SOURCE)
#define ENOTBLK         15
#endif
#define EBUSY           16
#define EEXIST          17
#define EXDEV           18
#define ENODEV          19
#define ENOTDIR         20
#define EISDIR          21
#define EINVAL          22
#define ENFILE          23
#define EMFILE          24
#define ENOTTY          25
#define ETXTBSY         26
#define EFBIG           27
#define ENOSPC          28
#define ESPIPE          29
#define EROFS           30
#define EMLINK          31
#define EPIPE           32
#define EDOM            33
#define ERANGE          34
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define EAGAIN          35 // 11 linux
#define EINPROGRESS     36 // 115 linux
#define EALREADY        37 // 114 linux
// error codes between 38–40 (Linux equivalents 88–90)
#define ENOTSOCK        38
#define EDESTADDRREQ    39
#define EMSGSIZE        40
#elif defined(__linux__)
#define EDEADLK         35
#define ENAMETOOLONG    36
#define ENOLCK          37
#define ENOSYS          38
#define ENOTEMPTY       39
#define ELOOP           40
#endif
#define EWOULDBLOCK     EAGAIN
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
// error codes between 41–61 (Linux equivalents 91–111)
#define EPROTOTYPE      41
#define ENOPROTOOPT     42
#define EPROTONOSUPPORT 43
#ifdef _BSD_SOURCE
#define ESOCKTNOSUPPORT 44
#endif
#define EOPNOTSUPP      45
#ifdef _BSD_SOURCE
#define EPFNOSUPPORT    46
#endif
#define EAFNOSUPPORT    47
#define EADDRINUSE      48
#define EADDRNOTAVAIL   49
#define ENETDOWN        50
#define ENETUNREACH     51
#define ENETRESET       52
#define ECONNABORTED    53
#define ECONNRESET      54
#define ENOBUFS         55
#define EISCONN         56
#define ENOTCONN        57
#ifdef _BSD_SOURCE
#define ESHUTDOWN       58
#define ETOOMANYREFS    59
#endif
#define ETIMEDOUT       60
#define ECONNREFUSED    61
#define ELOOP           62 // 40 linux
#define ENAMETOOLONG    63 // 36 linux
// error codes between 64–65 (Linux equivalents 112–113)
#ifdef _BSD_SOURCE
#define EHOSTDOWN       64
#endif
#define EHOSTUNREACH    65
#define ENOTEMPTY       66 // 39 linux
#ifdef _BSD_SOURCE
#define EPROCLIM        67 // bsd specific
#define EUSERS          68 // 87 linux
#endif
#define EDQUOT          69 // 122 linux
#define ESTALE          70 // 116 linux
#ifdef _BSD_SOURCE
#define EREMOTE         71 // 66 linux
// error codes between 72–76 are BSD specific
#define EBADRPC         72
#define ERPCMISMATCH    73
#define EPROGUNAVAIL    74
#define EPROGMISMATCH   75
#define EPROCUNAVAIL    76
#endif
// error codes between 77–78 (Linux equivalents 37–38)
#define ENOLCK          77
#define ENOSYS          78
// error codes between 79–83 are BSD specific
#ifdef _BSD_SOURCE
#define EFTYPE          79
#define EAUTH           80
#define ENEEDAUTH       81
#define EIPSEC          82
#define ENOATTR         83
#endif
#elif defined(__linux__)
#define ENOMSG          42
#define EIDRM           43
#define ECHRNG          44
#define EL2NSYNC        45
#define EL3HLT          46
#define EL3RST          47
#define ELNRNG          48
#define EUNATCH         49
#define ENOCSI          50
#define EL2HLT          51
#define EBADE           52
#define EBADR           53
#define EXFULL          54
#define ENOANO          55
#define EBADRQC         56
#define EBADSLT         57
#define EDEADLOCK       EDEADLK
#define EBFONT          59
#define ENOSTR          60
#define ENODATA         61
#define ETIME           62
#define ENOSR           63
#define ENONET          64
#define ENOPKG          65
#define EREMOTE         66
#define ENOLINK         67
#define EADV            68
#define ESRMNT          69
#define ECOMM           70
#define EPROTO          71
#define EMULTIHOP       72
#define EDOTDOT         73
#define EBADMSG         74
#define EOVERFLOW       75
#define ENOTUNIQ        76
#define EBADFD          77
#define EREMCHG         78
#define ELIBACC         79
#define ELIBBAD         80
#define ELIBSCN         81
#define ELIBMAX         82
#define ELIBEXEC        83
#endif
#define EILSEQ          84
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
// error codes between 85–86 (Linux equivalents 123–124)
#ifdef _BSD_SOURCE
#define ENOMEDIUM       85
#define EMEDIUMTYPE     86
#endif
#define EOVERFLOW       87 // 75 linux
#define ECANCELED       88 // 125 linux
#define EIDRM           89 // 43 linux
#define ENOMSG          90 // 42 linux
#define ENOTSUP         91 // EOPNOTSUPP (95) linux
#define EBADMSG         92 // 74 linux
#define ENOTRECOVERABLE 93 // 131 linux
#define EOWNERDEAD      94 // 130 linux
#define EPROTO          95 // 71 linux
#if __BSD_VISIBLE
#define ELAST           95 // bsd specific
#endif
#elif defined(__linux__)
#define ERESTART        85
#define ESTRPIPE        86
#define EUSERS          87
#define ENOTSOCK        88
#define EDESTADDRREQ    89
#define EMSGSIZE        90
#define EPROTOTYPE      91
#define ENOPROTOOPT     92
#define EPROTONOSUPPORT 93
#define ESOCKTNOSUPPORT 94
#define EOPNOTSUPP      95
#define ENOTSUP         EOPNOTSUPP
#endif
#if defined(__linux__)
#define EPFNOSUPPORT    96
#define EAFNOSUPPORT    97
#define EADDRINUSE      98
#define EADDRNOTAVAIL   99
#define ENETDOWN        100
#define ENETUNREACH     101
#define ENETRESET       102
#define ECONNABORTED    103
#define ECONNRESET      104
#define ENOBUFS         105
#define EISCONN         106
#define ENOTCONN        107
#define ESHUTDOWN       108
#define ETOOMANYREFS    109
#define ETIMEDOUT       110
#define ECONNREFUSED    111
#define EHOSTDOWN       112
#define EHOSTUNREACH    113
#define EALREADY        114
#define EINPROGRESS     115
#define ESTALE          116
#define EUCLEAN         117
#define ENOTNAM         118
#define ENAVAIL         119
#define EISNAM          120
#define EREMOTEIO       121
#define EDQUOT          122
#define ENOMEDIUM       123
#define EMEDIUMTYPE     124
#define ECANCELED       125
#define ENOKEY          126
#define EKEYEXPIRED     127
#define EKEYREVOKED     128
#define EKEYREJECTED    129
#define EOWNERDEAD      130
#define ENOTRECOVERABLE 131
#define ERFKILL         132
#define EHWPOISON       133
#endif
