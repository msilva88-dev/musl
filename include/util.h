#ifndef _UTIL_H
#define _UTIL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <pty.h>
#include <utmp.h>

pid_t fdforkpty(int, int *, char *, struct termios *, struct winsize *);
int fdopenpty(int, int *, int *, char *, struct termios *, struct winsize *);
int fmt_scaled(long long, char *);
int getptmfd(void);
int isduid(const char *, int);
void login(struct utmp *);
int pidfile(const char *);
int pw_abort(void);
void pw_copy(int, int, const struct passwd *, const struct passwd *);
void pw_edit(int, const char *);
void pw_error(const char *, int, int);
char *pw_file(const char *);
void pw_init(void);
int pw_lock(int);
int pw_mkdb(char *, int);
void pw_prompt(void);
int pw_scan(char *, struct passwd *, int *);
void pw_setdir(const char *);
int scan_scaled(char *, long long *);
int uu_lock(const char *);
int uu_lock_txfr(const char *, pid_t);
const char *uu_lockerr(int);
int uu_unlock(const char *);

#ifdef __cplusplus
}
#endif

#endif
