#ifndef CONCEAL_H
#define CONCEAL_H

#define CONCEAL_MAGIC 0x636F6E6365616C00ULL /* "conceal\0" */
#define CONCEAL_FLAG_MMAPPED 1
#define CONCEAL_FLAG_MLOCKED 2

struct conceal_hdr {
	uint64_t magic;
	size_t len;
	uint32_t flags, pad;
};

static inline struct conceal_hdr *conceal_hdr_from_user(void *p)
{
	if (!p) return NULL;
	return (struct conceal_hdr *)((char *)p - sizeof(struct conceal_hdr));
}

static inline size_t pagesize_round(size_t len)
{
	long page_size = sysconf(_SC_PAGESIZE);
	if (page_size <= 0) return len;
	size_t pg = (size_t)page_size;
	return (len + pg - 1) & ~(pg - 1);
}

#endif
