#ifndef _MCHUNK_H
#define _MCHUNK_H

#include <stdint.h>

#define MCHUNK_MAGIC 0xC0DECAFEu
#define MCHUNK_MAGIC_FREED 0xDEAD0000u
#define MCHUNK_FLAG_NONE 0x0
#define MCHUNK_FLAG_CONCEAL 0x1
#define MCHUNK_FLAG_GUARD 0x2

struct __mchunk {
	uint32_t magic;
	uint32_t flags;
	size_t user_len;
	size_t total_len;
	void *base;
};

static inline struct __mchunk *mchunk_from_user(void *p)
{
	return p ? (struct __mchunk *)((char *)p - sizeof(struct __mchunk)) : NULL;
}

#endif
