#ifndef _SYS_TTYDEFAULTS_H
#define _SYS_TTYDEFAULTS_H

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TTYDEF_IFLAG (BRKINT |          ICRNL | IMAXBEL | IXON | IXANY)
#define TTYDEF_OFLAG (OPOST | ONLCR)
#elif defined(__linux__)
#define TTYDEF_IFLAG (BRKINT | ISTRIP | ICRNL | IMAXBEL | IXON | IXANY)
#define TTYDEF_OFLAG (OPOST | ONLCR | XTABS)
#endif
#define TTYDEF_LFLAG (ECHO | ICANON | ISIG | IEXTEN | ECHOE|ECHOKE|ECHOCTL)
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define TTYDEF_CFLAG (CREAD | CS8          | HUPCL)
#elif defined(__linux__)
#define TTYDEF_CFLAG (CREAD | CS7 | PARENB | HUPCL)
#endif
#define TTYDEF_SPEED (B9600)
#define CTRL(x) ((x)&037)
#define CEOF CTRL('d')

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define CEOL '\xFF'
#define CSTATUS '\xFF'
#elif defined(__linux__)
#define CEOL '\0'
#define CSTATUS '\0'
#endif

#define CERASE 0177
#define CINTR CTRL('c')
#define CKILL CTRL('u')
#define CMIN 1
#define CQUIT 034
#define CSUSP CTRL('z')
#define CTIME 0
#define CDSUSP CTRL('y')
#define CSTART CTRL('q')
#define CSTOP CTRL('s')
#define CLNEXT CTRL('v')
#define CDISCARD CTRL('o')
#define CWERASE CTRL('w')
#define CREPRINT CTRL('r')
#define CEOT CEOF
#define CBRK CEOL
#define CRPRNT CREPRINT
#define CFLUSH CDISCARD

#endif
