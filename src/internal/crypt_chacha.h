#ifndef _INTERNAL_CRYPT_CHACHA_H
#define _INTERNAL_CRYPT_CHACHA_H

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "syscall.h"

enum {
	__IV = 8,
	__KIV = 40
};

struct __buffer {
	void *data;
	size_t bytes;
};

struct __chacha_ctx {
	uint32_t input[16];
};

static struct __chacha_buf {
	struct __chacha_ctx ctx;
	size_t bytes;
} __ccb;

hidden void __chacha_encrypt_bytes(struct __chacha_ctx *, const uint8_t *, uint8_t *, uint32_t);
hidden void __chacha_ivsetup(struct __chacha_ctx *, const uint8_t *);
hidden void __chacha_keysetup(struct __chacha_ctx *, const uint8_t *, uint32_t);

static inline void __dso_arc4rb(struct __buffer *buf)
{
	const uint32_t RK = 0x80000000U;
	const uint8_t KS = __KIV - __IV;

	if (__ccb.bytes) {
		__chacha_encrypt_bytes(&__ccb.ctx, buf->data, buf->data, buf->bytes);

		if (__ccb.bytes > RK || __ccb.bytes + buf->bytes > RK) {
			__ccb.bytes = 0;
			return;
		}

		__ccb.bytes += buf->bytes;
		return;
	}

	char bytes[__KIV];

	if (getentropy(bytes, __KIV) == 0) {
		__chacha_keysetup(&__ccb.ctx, (uint8_t *)bytes, 256);
		__chacha_ivsetup(&__ccb.ctx, (uint8_t *)(KS + bytes));

		if (getentropy(bytes, __KIV) == 0) {
			return;
		}

		fprintf(stderr, "Cannot overwrite RNG key\n");
		abort();
	} else {
		fprintf(stderr, "Lack of entropy\n");
		abort();
	}

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	syscall(SYS_thrkill, 0, 9, NULL);
#elif defined(__linux__)
	syscall(SYS_tkill, 0, 9);
#endif
}

#endif
