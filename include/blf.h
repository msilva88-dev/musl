#ifndef _BLF_H
#define _BLF_H

#ifdef __cplusplus
extern "C" {
#endif

#include <bits/alltypes.h>
#include <stdint.h>

enum bsdbf_e {
	BSDBF_ROUNDS = 16,
	BSDBF_P_COUNT = 18,
	BSDBF_KEY_BYTES_MAX = 56,
	BSDBF_PARRAY_BYTES = 72
};

#define BLF_N BSDBF_ROUNDS
#define BLF_MAXKEYLEN BSDBF_KEY_BYTES_MAX
#define BLF_MAXUTILIZED BSDBF_PARRAY_BYTES

typedef struct {
        uint32_t P[BSDBF_P_COUNT];
        uint32_t S[4][256];
} bsdbf_ctx_t;

typedef bsdbf_ctx_t blf_ctx;

#ifdef _BSD_SOURCE
/* API (datalen must be multiple of 8 for ECB/CBC; blocks is number of 64-bit blocks) */
void bsdbf_cbc_dec(bsdbf_ctx_t *, uint8_t *, uint8_t *, uint32_t);
void bsdbf_cbc_enc(bsdbf_ctx_t *, uint8_t *, uint8_t *, uint32_t);
void bsdbf_dec(bsdbf_ctx_t *, uint32_t *, uint16_t);
void bsdbf_deciph(bsdbf_ctx_t *, uint32_t *, uint32_t *);
void bsdbf_ecb_dec(bsdbf_ctx_t *, uint8_t *, uint32_t);
void bsdbf_ecb_enc(bsdbf_ctx_t *, uint8_t *, uint32_t);
void bsdbf_enc(bsdbf_ctx_t *, uint32_t *, uint16_t);
void bsdbf_enciph(bsdbf_ctx_t *, uint32_t *, uint32_t *);
void bsdbf_expst(bsdbf_ctx_t *, const uint8_t *, uint16_t, const uint8_t *, uint16_t);
void bsdbf_expst3(bsdbf_ctx_t *, const uint8_t *, uint16_t);
void bsdbf_init(bsdbf_ctx_t *);
void bsdbf_key(bsdbf_ctx_t *, const uint8_t *, uint16_t);
uint32_t bsdbf_strtowrd(const uint8_t *, uint16_t, uint16_t *);

#define blf_cbc_decrypt(ctx, iv, dat, len) (bsdbf_cbc_dec((bsdbf_ctx_t)(ctx), (iv), (dat), (len)))
#define blf_cbc_encrypt(ctx, iv, dat, len) (bsdbf_cbc_enc((bsdbf_ctx_t)(ctx), (iv), (dat), (len)))
#define blf_dec(ctx, dat, blk) (bsdbf_dec((bsdbf_ctx_t)(ctx), (dat), (blk)))
#define blf_ecb_decrypt(ctx, dat, len) (bsdbf_ecb_dec((bsdbf_ctx_t)(ctx), (dat), (len)))
#define blf_ecb_encrypt(ctx, dat, len) (bsdbf_ecb_enc((bsdbf_ctx_t)(ctx), (dat), (len)))
#define blf_enc(ctx, dat, blk) (bsdbf_enc((bsdbf_ctx_t)(ctx), (dat), (blk)))
#define blf_key(ctx, key, len) (bsdbf_key((bsdbf_ctx_t)(ctx), (key), (len)))
#define Blowfish_decipher(ctx, l, r) (bsdbf_deciph((bsdbf_ctx_t)(ctx), (l), (r)))
#define Blowfish_encipher(ctx, l, r) (bsdbf_enciph((bsdbf_ctx_t)(ctx), (l), (r)))
#define Blowfish_expand0state(ctx, dat, len) (bsdbf_expst3((bsdbf_ctx_t)(ctx), (dat), (len)))
#define Blowfish_expandstate(ctx, slt, sl, key, kl) (bsdbf_expst((bsdbf_ctx_t)(ctx), (slt), (sl), (key), (kl)))
#define Blowfish_initstate(ctx) (bsdbf_init((bsdbf_ctx_t)(ctx)))
#define Blowfish_stream2word(dat, len, off) (bsdbf_strtowrd((dat), (len), (off)))
#endif

#ifdef __cplusplus
}
#endif

#endif
