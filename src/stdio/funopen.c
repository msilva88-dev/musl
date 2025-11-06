#define _BSD_SOURCE
#include "stdio_impl.h"
#include <stdlib.h>
#include <errno.h>
#include <string.h>

struct fun_cookie {
	void *cookie;
	int (*readfn)(void *, char *, int);
	int (*writefn)(void *, const char *, int);
	fpos_t (*seekfn)(void *, fpos_t, int);
	int (*closefn)(void *);
};

struct fun_FILE {
	FILE f;
	struct fun_cookie fc;
	unsigned char buf[UNGET+BUFSIZ];
};

static size_t fun_read(FILE *f, unsigned char *buf, size_t len)
{
	struct fun_cookie *fc = f->cookie;
	int ret;

	if (!fc->readfn) {
		f->flags |= F_ERR;
		return 0;
	}

	ret = fc->readfn(fc->cookie, (char *)buf, (int)len);
	if (ret <= 0) {
		if (ret == 0) f->flags |= F_EOF;
		else f->flags |= F_ERR;
		return 0;
	}
	return (size_t)ret;
}

static size_t fun_write(FILE *f, const unsigned char *buf, size_t len)
{
	struct fun_cookie *fc = f->cookie;
	int ret;

	if (!fc->writefn) {
		f->flags |= F_ERR;
		return 0;
	}

	ret = fc->writefn(fc->cookie, (const char *)buf, (int)len);
	if (ret < 0) {
		f->flags |= F_ERR;
		return 0;
	}
	return (size_t)ret;
}

static off_t fun_seek(FILE *f, off_t off, int whence)
{
	struct fun_cookie *fc = f->cookie;
	fpos_t pos;

	if (!fc->seekfn) {
		errno = ENOTSUP;
		return -1;
	}

	pos = fc->seekfn(fc->cookie, (fpos_t)off, whence);
	if (pos == -1) return -1;

	return (off_t)pos;
}

static int fun_close(FILE *f)
{
	struct fun_cookie *fc = f->cookie;
	if (fc->closefn) return fc->closefn(fc->cookie);
	return 0;
}

FILE *funopen(const void *cookie,
              int (*readfn)(void *, char *, int),
              int (*writefn)(void *, const char *, int),
              fpos_t (*seekfn)(void *, fpos_t, int),
              int (*closefn)(void *))
{
	struct fun_FILE *f;

	/* Check for valid initial mode character */
	if (!readfn && !writefn) {
		errno = EINVAL;
		return NULL;
	}

	/* Allocate FILE+fcookie+buffer or fail */
	f = malloc(sizeof *f);
	if (!f) return NULL;

	/* Zero-fill only the struct, not the buffer */
	memset(&f->f, 0, sizeof f->f);

	/* Impose mode restrictions */
	if (readfn && !writefn) f->f.flags = F_NORD;
	else if (writefn && !readfn) f->f.flags = F_NOWR;

	/* Set up our fcookie */
	f->fc.cookie = (void *)cookie;
	f->fc.readfn = readfn;
	f->fc.writefn = writefn;
	f->fc.seekfn = seekfn;
	f->fc.closefn = closefn;

	f->f.fd = -1;
	f->f.cookie = &f->fc;
	f->f.buf = f->buf + UNGET;
	f->f.buf_size = sizeof f->buf - UNGET;
	f->f.lbf = EOF;

	/* Initialize op ptrs. No problem if some are unneeded. */
	f->f.read = fun_read;
	f->f.write = fun_write;
	f->f.seek = fun_seek;
	f->f.close = fun_close;

	/* Add new FILE to open file list */
	return __ofl_add(&f->f);
}

FILE *fropen(const void *cookie, int (*readfn)(void *, char *, int))
{
	return funopen(cookie, readfn, NULL, NULL, NULL);
}

FILE *fwopen(const void *cookie, int (*writefn)(void *, const char *, int))
{
	return funopen(cookie, NULL, writefn, NULL, NULL);
}
