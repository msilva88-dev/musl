/*
chacha-merged.c version 20080118
D. J. Bernstein
Public domain.
*/

/* ChaCha cipher from OpenBSD 7.0 source code: lib/libc/crypt/chacha_private.h */

#define _BSD_SOURCE
#include "crypt_chacha.h"

static const char SIGMA[16] = "expand 32-byte k", TAU[16] = "expand 16-byte k";

static inline uint32_t u32v(uint32_t v)
{
	return v & 0xFFFFFFFF;
}

static inline uint8_t u8v(uint32_t v)
{
	return (uint8_t)(v & 0xFF);
}

static inline void u32to8_little(uint8_t *p, uint32_t v)
{
	p[0] = u8v(v);
	p[1] = u8v(v >> 8);
	p[2] = u8v(v >> 16);
	p[3] = u8v(v >> 24);
}

static inline uint32_t u8to32_little(const uint8_t *p)
{
	return (uint32_t)p[0]
		| ((uint32_t)p[1] << 8)
		| ((uint32_t)p[2] << 16)
		| ((uint32_t)p[3] << 24);
}

static inline uint32_t plus32(uint32_t v, uint32_t w)
{
	return u32v(v + w);
}

static inline uint32_t plusone32(uint32_t v)
{
	return plus32(v, 1);
}

static inline uint32_t rotl32(uint32_t v, int n)
{
	return u32v((v << n) | (v >> (32 - n)));
}

static inline uint32_t xor32(uint32_t v, uint32_t w)
{
	return v ^ w;
}

static inline void quarterround32(uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d)
{
	*a = plus32(*a, *b);
	*d = rotl32(xor32(*d, *a), 16);

	*c = plus32(*c, *d);
	*b = rotl32(xor32(*b, *c), 12);

	*a = plus32(*a, *b);
	*d = rotl32(xor32(*d, *a), 8);

	*c = plus32(*c, *d);
	*b = rotl32(xor32(*b, *c), 7);
}

void __chacha_encrypt_bytes(struct __chacha_ctx *x, const uint8_t *m, uint8_t *c, uint32_t bytes)
{
	uint32_t x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15;
	uint32_t j0, j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11, j12, j13, j14, j15;
	uint8_t *ctarget = NULL;
	uint8_t tmp[64];
	unsigned int i;

	if (!bytes) return;

	j0 = x->input[0];
	j1 = x->input[1];
	j2 = x->input[2];
	j3 = x->input[3];
	j4 = x->input[4];
	j5 = x->input[5];
	j6 = x->input[6];
	j7 = x->input[7];
	j8 = x->input[8];
	j9 = x->input[9];
	j10 = x->input[10];
	j11 = x->input[11];
	j12 = x->input[12];
	j13 = x->input[13];
	j14 = x->input[14];
	j15 = x->input[15];

	for (;;) {
		if (bytes < 64) {
			for (i = 0; i < bytes; ++i) tmp[i] = m[i];

			m = tmp;
			ctarget = c;
			c = tmp;
		}

		x0 = j0;
		x1 = j1;
		x2 = j2;
		x3 = j3;
		x4 = j4;
		x5 = j5;
		x6 = j6;
		x7 = j7;
		x8 = j8;
		x9 = j9;
		x10 = j10;
		x11 = j11;
		x12 = j12;
		x13 = j13;
		x14 = j14;
		x15 = j15;

		for (i = 20; i > 0; i -= 2) {
			quarterround32(&x0, &x4, &x8, &x12);
			quarterround32(&x1, &x5, &x9, &x13);
			quarterround32(&x2, &x6, &x10, &x14);
			quarterround32(&x3, &x7, &x11, &x15);
			quarterround32(&x0, &x5, &x10, &x15);
			quarterround32(&x1, &x6, &x11, &x12);
			quarterround32(&x2, &x7, &x8, &x13);
			quarterround32(&x3, &x4, &x9, &x14);
		}

		x0 = plus32(x0, j0);
		x1 = plus32(x1, j1);
		x2 = plus32(x2, j2);
		x3 = plus32(x3, j3);
		x4 = plus32(x4, j4);
		x5 = plus32(x5, j5);
		x6 = plus32(x6, j6);
		x7 = plus32(x7, j7);
		x8 = plus32(x8, j8);
		x9 = plus32(x9, j9);
		x10 = plus32(x10, j10);
		x11 = plus32(x11, j11);
		x12 = plus32(x12, j12);
		x13 = plus32(x13, j13);
		x14 = plus32(x14, j14);
		x15 = plus32(x15, j15);

		j12 = plusone32(j12);
		if (!j12) {
			j13 = plusone32(j13);
			/* stopping at 2^70 bytes per nonce is user's responsibility */
		}

		u32to8_little(c + 0, x0);
		u32to8_little(c + 4, x1);
		u32to8_little(c + 8, x2);
		u32to8_little(c + 12, x3);
		u32to8_little(c + 16, x4);
		u32to8_little(c + 20, x5);
		u32to8_little(c + 24, x6);
		u32to8_little(c + 28, x7);
		u32to8_little(c + 32, x8);
		u32to8_little(c + 36, x9);
		u32to8_little(c + 40, x10);
		u32to8_little(c + 44, x11);
		u32to8_little(c + 48, x12);
		u32to8_little(c + 52, x13);
		u32to8_little(c + 56, x14);
		u32to8_little(c + 60, x15);

		if (bytes <= 64) {
			if (bytes < 64) {
				for (i = 0; i < bytes; ++i) ctarget[i] = c[i];
			}

			x->input[12] = j12;
			x->input[13] = j13;

			return;
		}

		bytes -= 64;
		c += 64;
	}
}

void __chacha_ivsetup(struct __chacha_ctx *x, const uint8_t *iv)
{
	x->input[12] = 0;
	x->input[13] = 0;
	x->input[14] = u8to32_little(iv + 0);
	x->input[15] = u8to32_little(iv + 4);
}

void __chacha_keysetup(struct __chacha_ctx *x, const uint8_t *k, uint32_t kbits)
{
	if (kbits != 128 && kbits != 256) return;

	const uint8_t *constants;

	x->input[4] = u8to32_little(k + 0);
	x->input[5] = u8to32_little(k + 4);
	x->input[6] = u8to32_little(k + 8);
	x->input[7] = u8to32_little(k + 12);

	if (kbits == 256) { /* recommended */
		k += 16;
		constants = (const uint8_t *)SIGMA;
	} else { /* kbits == 128 */
		constants = (const uint8_t *)TAU;
	}

	x->input[8] = u8to32_little(k + 0);
	x->input[9] = u8to32_little(k + 4);
	x->input[10] = u8to32_little(k + 8);
	x->input[11] = u8to32_little(k + 12);
	x->input[0] = u8to32_little(constants + 0);
	x->input[1] = u8to32_little(constants + 4);
	x->input[2] = u8to32_little(constants + 8);
	x->input[3] = u8to32_little(constants + 12);
}
