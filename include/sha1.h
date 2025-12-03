/*
 * SHA-1 in C
 * By Steve Reid <steve@edmweb.com>
 * 100% Public Domain
 */

/* sha1 header from OpenBSD 7.0 source code: include/sha1.h */

#ifndef _SHA1_H
#define _SHA1_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>

#define	SHA1_BLOCK_LENGTH 64
#define	SHA1_DIGEST_LENGTH 20
#define	SHA1_DIGEST_STRING_LENGTH (SHA1_DIGEST_LENGTH * 2 + 1)

typedef struct {
	uint32_t state[5];
	uint64_t count;
	uint8_t buffer[SHA1_BLOCK_LENGTH];
} SHA1_CTX;

char *SHA1Data(const uint8_t *, size_t, char *);
char *SHA1End(SHA1_CTX *, char *);
char *SHA1File(const char *, char *);
char *SHA1FileChunk(const char *, char *, off_t, off_t);
void SHA1Final(uint8_t [SHA1_DIGEST_LENGTH], SHA1_CTX *);
void SHA1Init(SHA1_CTX *);
void SHA1Pad(SHA1_CTX *);
void SHA1Transform(uint32_t [5], const uint8_t [SHA1_BLOCK_LENGTH]);
void SHA1Update(SHA1_CTX *, const uint8_t *, size_t);

#define HTONDIGEST(x) do {		\
	x[0] = htonl(x[0]);		\
	x[1] = htonl(x[1]);		\
	x[2] = htonl(x[2]);		\
	x[3] = htonl(x[3]);		\
	x[4] = htonl(x[4]); } while (0)

#define NTOHDIGEST(x) do {		\
	x[0] = ntohl(x[0]);		\
	x[1] = ntohl(x[1]);		\
	x[2] = ntohl(x[2]);		\
	x[3] = ntohl(x[3]);		\
	x[4] = ntohl(x[4]); } while (0)

#ifdef __cplusplus
}
#endif

#endif
