#ifndef _FSTAB_H
#define _FSTAB_H

#ifdef __cplusplus
extern "C" {
#endif

#include <paths.h>

#define __FSTABSPEC(fstabe) ( \
	(fstabe) >= 0 && (fstabe) <= 3 \
	? ((const char *[]){ \
		"rw", \
		"rq", \
		"ro", \
		"sw", \
	}[(fstabe)]) \
	: "xx" \
	)

#define FSTAB_RW __FSTABSPEC(0)
#define FSTAB_RQ __FSTABSPEC(1)
#define FSTAB_RO __FSTABSPEC(2)
#define FSTAB_SW __FSTABSPEC(3)
#define FSTAB_XX __FSTABSPEC(-1)

struct fstab {
	char *fs_spec, *fs_file, *fs_vfstype, *fs_mntops, *fs_type;
	int fs_freq, fs_passno;
};

struct ttyent {
	char *ty_name, *ty_getty, *ty_type;
	int ty_status;
	char *ty_window, *ty_comment;
};

#ifdef _BSD_SOURCE
struct fstab *getfsspec(const char *);
struct fstab *getfsfile(const char *);
struct fstab *getfsent(void);
int setfsent(void);
void endfsent(void);
#endif

#ifdef __cplusplus
}
#endif

#endif
