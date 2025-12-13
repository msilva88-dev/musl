#ifndef _UTIL_H
#define _UTIL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <pty.h>
#include <utmp.h>

#ifdef _BSD_SOURCE
int bcrypt_pbkdf(const char *, size_t, const uint8_t *, size_t, uint8_t *, size_t, unsigned int);
pid_t fdforkpty(int, int *, char *, struct termios *, struct winsize *);
int fdopenpty(int, int *, int *, char *, struct termios *, struct winsize *);
int fmt_scaled(long long, char *);
int getmaxpartitions(void);
int getptmfd(void);
int getrawpartition(void);
int isduid(const char *, int);
void login(struct utmp *);
void login_fbtab(const char *, uid_t, gid_t);
int logout(const char *);
void logwtmp(const char *, const char *, const char *);
int pidfile(const char *);
int pkcs5_pbkdf2(const char *, size_t, const uint8_t *, size_t, uint8_t *, size_t, unsigned int);
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
#endif

#ifdef __cplusplus
}
#endif

#endif
