#ifndef _ICDB_H
#define _ICDB_H

#ifdef __cplusplus
extern "C" {
#endif

struct icdb;
int icdb_add(struct icdb *, const void *);
int icdb_close(struct icdb *);
const void *icdb_entries(struct icdb *);
int icdb_get(struct icdb *, void *, uint32_t);
int icdb_lookup(struct icdb *, int, const void *, void *, uint32_t *);
int icdb_nentries(struct icdb *);
struct icdb *icdb_new(uint32_t, uint32_t, uint32_t, uint32_t, const uint32_t *, const uint32_t *);
struct icdb *icdb_open(const char *, int, uint32_t);
int icdb_update(struct icdb *, const void *, int);
int icdb_rehash(struct icdb *);
int icdb_save(struct icdb *, int);

#ifdef __cplusplus
}
#endif

#endif
