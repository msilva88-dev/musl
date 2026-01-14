#ifndef _UUID_H
#define _UUID_H

#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_int32_t
#define __NEED_uint8_t
#define __NEED_uint16_t
#define __NEED_uint32_t

#include <bits/alltypes.h>

enum __uuid_len { UUID_STR_LEN = 36, UUID_BUF_LEN = 38 };
enum __uuid_stat { uuid_s_ok, uuid_s_bad_version, uuid_s_invalid_string_uuid, uuid_s_no_memory };

typedef struct uuid {
	uint32_t time_low;
	uint16_t time_mid, time_hi_and_version;
	uint8_t clock_seq_hi_and_reserved, clock_seq_low, node[6];
} uuid_t;

#ifdef _BSD_SOURCE
int32_t uuid_compare(const uuid_t *, const uuid_t *, uint32_t *);
void uuid_create(uuid_t *, uint32_t *);
void uuid_create_nil(uuid_t *, uint32_t *);
void uuid_dec_be(const void *, uuid_t *);
void uuid_dec_le(const void *, uuid_t *);
int32_t uuid_equal(const uuid_t *, const uuid_t *, uint32_t *);
void uuid_enc_be(void *, const uuid_t *);
void uuid_enc_le(void *, const uuid_t *);
void uuid_from_string(const char *, uuid_t *, uint32_t *);
uint16_t uuid_hash(const uuid_t *, uint32_t *);
int32_t uuid_is_nil(const uuid_t *, uint32_t *);
void uuid_to_string(const uuid_t *, char **, uint32_t *);
#endif

#ifdef __cplusplus
}
#endif

#endif
