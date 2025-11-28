#ifndef _BLF_H
#define _BLF_H

#ifdef __cplusplus
extern "C" {
#endif

#include <bits/alltypes.h>

#define BLF_N 16
/* Maximum key length per Blowfish spec: 448 bits */
#define BLF_MAXKEYLEN 56
/* Size of P-array in bytes (18 * 4 = 72 bytes = 576 bits) */
#define BLF_MAXUTILIZED 72

typedef struct {
        uint32_t P[18];
        uint32_t S[4][256];
} blf_ctx;

#ifdef _BSD_SOURCE
/* API (datalen must be multiple of 8 for ECB/CBC; blocks is number of 64-bit blocks) */
void blf_cbc_decrypt(blf_ctx *, uint8_t *, uint8_t *, uint32_t);
void blf_cbc_encrypt(blf_ctx *, uint8_t *, uint8_t *, uint32_t);
void blf_dec(blf_ctx *, uint32_t *, uint16_t);
void blf_ecb_decrypt(blf_ctx *, uint8_t *, uint32_t);
void blf_ecb_encrypt(blf_ctx *, uint8_t *, uint32_t);
void blf_enc(blf_ctx *, uint32_t *, uint16_t);
void blf_key(blf_ctx *, const uint8_t *, uint16_t);

void Blowfish_decipher(blf_ctx *, uint32_t *, uint32_t *);
void Blowfish_encipher(blf_ctx *, uint32_t *, uint32_t *);
void Blowfish_expand0state(blf_ctx *, const uint8_t *, uint16_t);
void Blowfish_expandstate(blf_ctx *, const uint8_t *, uint16_t, const uint8_t *, uint16_t);
void Blowfish_initstate(blf_ctx *);
uint32_t Blowfish_stream2word(const uint8_t *, uint16_t , uint16_t *);
#endif

#ifdef __cplusplus
}
#endif

#endif
