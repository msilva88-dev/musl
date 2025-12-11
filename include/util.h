#ifndef _UTIL_H
#define _UTIL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <pty.h>
#include <utmp.h>

pid_t fdforkpty(int, int *, char *, struct termios *, struct winsize *);
int fdopenpty(int, int *, int *, char *, struct termios *, struct winsize *);
int getptmfd(void);
int pidfile(const char *);

#ifdef __cplusplus
}
#endif

#endif
