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
int isduid(const char *, int);
int pidfile(const char *);
int uu_lock(const char *);
int uu_lock_txfr(const char *, pid_t);
const char *uu_lockerr(int);
int uu_unlock(const char *);

#ifdef __cplusplus
}
#endif

#endif
