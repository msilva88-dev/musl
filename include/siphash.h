/*
 * Copyright (c) 2013 Andre Oppermann <andre@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* siphash header from OpenBSD 7.0 source code: include/siphash.h */

#ifndef _SIPHASH_H
#define _SIPHASH_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>

#define SIPHASH_BLOCK_LENGTH 8
#define SIPHASH_DIGEST_LENGTH 8
#define SIPHASH_KEY_LENGTH 16

typedef struct _SIPHASH_CTX {
	uint64_t v[4];
	uint8_t buf[SIPHASH_BLOCK_LENGTH];
	uint32_t bytes;
} SIPHASH_CTX;

typedef struct {
	uint64_t k0;
	uint64_t k1;
} SIPHASH_KEY;

uint64_t SipHash(const SIPHASH_KEY *, int, int, const void *, size_t);
uint64_t SipHash_End(SIPHASH_CTX *, int, int);
void SipHash_Final(void *, SIPHASH_CTX *, int, int);
void SipHash_Init(SIPHASH_CTX *, const SIPHASH_KEY *);
void SipHash_Update(SIPHASH_CTX *, int, int, const void *, size_t);

#define SipHash24(k, p, l) (SipHash((k), 2, 4, (p), (l)))
#define SipHash24_End(d) (SipHash_End((d), 2, 4))
#define SipHash24_Final(d, c) (SipHash_Final((d), (c), 2, 4))
#define SipHash24_Init(c, k) (SipHash_Init((c), (k)))
#define SipHash24_Update(c, p, l) (SipHash_Update((c), 2, 4, (p), (l)))
#define SipHash48(k, p, l) (SipHash((k), 4, 8, (p), (l)))
#define SipHash48_End(d) (SipHash_End((d), 4, 8))
#define SipHash48_Final(d, c) (SipHash_Final((d), (c), 4, 8))
#define SipHash48_Init(c, k) (SipHash_Init((c), (k)))
#define SipHash48_Update(c, p, l) (SipHash_Update((c), 4, 8, (p), (l)))

#ifdef __cplusplus
}
#endif

#endif
