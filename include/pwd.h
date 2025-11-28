#ifndef _PWD_H
#define _PWD_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#define __NEED_size_t
#define __NEED_uid_t
#define __NEED_gid_t

#ifdef _GNU_SOURCE
#define __NEED_FILE
#endif

#include <bits/alltypes.h>

struct passwd {
	char *pw_name;
	char *pw_passwd;
	uid_t pw_uid;
	gid_t pw_gid;
	char *pw_gecos;
	char *pw_dir;
	char *pw_shell;
};

#if defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
int setpassent(int);
void setpwent (void);
void endpwent (void);
struct passwd *getpwent (void);
#endif

struct passwd *getpwuid (uid_t);
struct passwd *getpwnam (const char *);
int getpwuid_r (uid_t, struct passwd *, char *, size_t, struct passwd **);
int getpwnam_r (const char *, struct passwd *, char *, size_t, struct passwd **);

#ifdef _GNU_SOURCE
struct passwd *fgetpwent(FILE *);
int putpwent(const struct passwd *, FILE *);
#endif

#ifdef _BSD_SOURCE
char *bcrypt(const char *, const char *);
int bcrypt_checkpass(const char *, const char *);
char *bcrypt_gensalt(uint8_t);
int bcrypt_newhash(const char *, int, char *, size_t);
struct passwd *pw_dup(const struct passwd *);
const char *user_from_uid(uid_t, int);
int uid_from_user(const char *, uid_t *);
#endif

#ifdef __cplusplus
}
#endif

#endif
