#ifndef _VIS_H
#define _VIS_H

#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_size_t
#define __NEED_ssize_t

#include <bits/alltypes.h>

enum __vis_e {
	VIS_OCTAL = 00001,
	VIS_CSTYLE = 00002,
	VIS_SP = 00004,
	VIS_TAB = 00010,
	VIS_NL = 00020,
	VIS_WHITE = (VIS_NL|VIS_SP|VIS_TAB),
	VIS_SAFE = 00040,
	VIS_NOSLASH = 00100,
	VIS_GLOB = 00400,
	VIS_DQ = 01000,
	VIS_ALL = 02000
};

enum __unvis_e {
	UNVIS_ERROR = -2,
	UNVIS_SYNBAD = -1,
	UNVIS_VALID = 1,
	UNVIS_END = UNVIS_VALID,
	UNVIS_VALIDPUSH = 2,
	UNVIS_NOCHAR = 3
};

#ifdef _BSD_SOURCE
char *vis(char *, int, int, int);
int strvis(char *, const char *, int);
int stravis(char **, const char *, int);
int strnvis(char *, const char *, size_t, int);
int strvisx(char *, const char *, size_t, int);
int strunvis(char *, const char *);
int unvis(char *, char, int *, int);
ssize_t strnunvis(char *, const char *, size_t);
#endif

#ifdef __cplusplus
}
#endif

#endif
