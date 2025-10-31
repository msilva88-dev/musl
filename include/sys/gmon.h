#ifndef _SYS_GMON_H
#define _SYS_GMON_H

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned short histcounter_t
#define HISTCOUNTER histcounter_t

#define HISTFRACTION 0x00002
enum __gmon_e {
	HASHFRACTION = HISTFRACTION,
	ARCDENSITY = HISTFRACTION,
	MINARCS = 0x00032,
	MAXARCS = -2 + (1 << (sizeof(histcounter_t)*8)),
	GMONVERSION = 0x51879
};

struct gmonhdr {
	unsigned long lpc, hpc;
	int ncnt, version, profrate, spare[3];
};

struct gmonparam {
	int state;
	histcounter_t *kcount;
	unsigned long kcountsize;
	histcounter_t *froms;
	unsigned long fromssize;
	struct tostruct {
		unsigned long selfpc;
		long count;
		histcounter_t link, pad;
	}*tos;
	unsigned long tossize;
	long tolimit;
        unsigned long lowpc, highpc, textsize, hashfraction;
};

struct rawarc {
	unsigned long raw_frompc, raw_selfpc;
	long raw_count;
};

static inline unsigned long __rounddown(unsigned long x, unsigned char y)
{
	return y*(x/y);
}
#define ROUNDDOWN(x,y) __rounddown((x), (y))

static inline unsigned long __roundup(unsigned long x, unsigned char y)
{
	return y*((y+x-1)/y);
}
#define ROUNDDOWN(x,y) __roundup((x), (y))

enum { GMON_PROF_ON, GMON_PROF_BUSY, GMON_PROF_ERROR, GMON_PROF_OFF };
enum { GPROF_STATE, GPROF_COUNT, GPROF_FROMS, GPROF_TOS, GPROF_GMONPARAM };

#if defined _BSD_SOURCE
void moncontrol(int);
void monstartup(unsigned long, unsigned long);
#endif

#ifdef __cplusplus
}
#endif

#endif
