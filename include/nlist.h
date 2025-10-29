#ifndef _NLIST_H
#define _NLIST_H

#ifdef __cplusplus
extern "C" {
#endif

#define N_EXT 0001
#define N_FORMAT "%08x"
#define N_STAB 0340

enum __nlist_e {
	N_UNDF = 00,
	N_ABS = 02,
	N_TEXT = 04,
	N_DATA = 06,
	N_BSS = 08,
	N_INDR = 10,
	N_SIZE = 12,
	N_COMM = 18,
	N_WARN = 30,
	N_FN = N_WARN,
	N_TYPE = N_WARN
};

struct nlist {
	union {
		char *n_name;
		long n_strx;
        } n_un;
#ifndef n_name
#define n_name n_un.n_name
#endif
        unsigned char n_type;
        char n_other;
	union {
		short n_desc;
		short n_hash;
	} __n_un;
#define n_desc __n_un.n_desc
#define n_hash __n_un.n_hash
        unsigned long n_value;
};

#ifdef _BSD_SOURCE
int nlist(const char *, struct nlist *);
#endif

#ifdef __cplusplus
}
#endif

#endif
