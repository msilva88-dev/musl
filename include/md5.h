/*
 * This code implements the MD5 message-digest algorithm.
 * The algorithm is due to Ron Rivest.  This code was
 * written by Colin Plumb in 1993, no copyright is claimed.
 * This code is in the public domain; do with it what you wish.
 *
 * Equivalent code is available from RSA Data Security, Inc.
 * This code has been tested against that, and is equivalent,
 * except that you don't need to include two pages of legalese
 * with every copy.
 */

/* md5 header from OpenBSD 7.0 source code: include/md5.h */

#ifndef _MD5_H
#define _MD5_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>

#define	MD5_BLOCK_LENGTH 64
#define	MD5_DIGEST_LENGTH 16
#define	MD5_DIGEST_STRING_LENGTH (MD5_DIGEST_LENGTH * 2 + 1)

typedef struct MD5Context {
	uint32_t state[4];
	uint64_t count;
	uint8_t buffer[MD5_BLOCK_LENGTH];
} MD5_CTX;

char *MD5Data(const uint8_t *, size_t, char *);
char *MD5End(MD5_CTX *, char *);
char *MD5File(const char *, char *);
char *MD5FileChunk(const char *, char *, off_t, off_t);
void MD5Final(uint8_t [MD5_DIGEST_LENGTH], MD5_CTX *);
void MD5Init(MD5_CTX *);
void MD5Pad(MD5_CTX *);
void MD5Transform(uint32_t [4], const uint8_t [MD5_BLOCK_LENGTH]);
void MD5Update(MD5_CTX *, const uint8_t *, size_t);

#ifdef __cplusplus
}
#endif

#endif
