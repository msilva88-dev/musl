#ifndef _STDLIB_H
#define _STDLIB_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#if __cplusplus >= 201103L
#define NULL nullptr
#elif defined(__cplusplus)
#define NULL 0L
#else
#define NULL ((void*)0)
#endif

#define __NEED_size_t
#define __NEED_wchar_t

#include <bits/alltypes.h>
#ifdef _BSD_SOURCE
#include <sys/types.h>
#endif

int atoi (const char *);
long atol (const char *);
long long atoll (const char *);
double atof (const char *);

float strtof (const char *__restrict, char **__restrict);
double strtod (const char *__restrict, char **__restrict);
long double strtold (const char *__restrict, char **__restrict);

long strtol (const char *__restrict, char **__restrict, int);
unsigned long strtoul (const char *__restrict, char **__restrict, int);
long long strtoll (const char *__restrict, char **__restrict, int);
unsigned long long strtoull (const char *__restrict, char **__restrict, int);
#ifdef _BSD_SOURCE
quad_t strtoq (const char *__restrict, char **__restrict, int);
u_quad_t strtouq (const char *__restrict, char **__restrict, int);
long long strtonum(const char *, long long, long long, const char **);
#endif

int rand (void);
void srand (unsigned);

void *malloc (size_t);
void *calloc (size_t, size_t);
void *realloc (void *, size_t);
void free (void *);
void *aligned_alloc(size_t, size_t);

_Noreturn void abort (void);
int atexit (void (*) (void));
_Noreturn void exit (int);
_Noreturn void _Exit (int);
int at_quick_exit (void (*) (void));
_Noreturn void quick_exit (int);

char *getenv (const char *);

int system (const char *);

void *bsearch (const void *, const void *, size_t, size_t, int (*)(const void *, const void *));
void qsort (void *, size_t, size_t, int (*)(const void *, const void *));

int abs (int);
long labs (long);
long long llabs (long long);

typedef struct { int quot, rem; } div_t;
typedef struct { long quot, rem; } ldiv_t;
typedef struct { long long quot, rem; } lldiv_t;
#ifdef _BSD_SOURCE
typedef struct { quad_t quot, rem; } qdiv_t;
#endif

div_t div (int, int);
ldiv_t ldiv (long, long);
lldiv_t lldiv (long long, long long);

#ifdef _BSD_SOURCE
quad_t qabs (quad_t);
qdiv_t qdiv (quad_t, quad_t);
#endif

int mblen (const char *, size_t);
int mbtowc (wchar_t *__restrict, const char *__restrict, size_t);
int wctomb (char *, wchar_t);
size_t mbstowcs (wchar_t *__restrict, const char *__restrict, size_t);
size_t wcstombs (char *__restrict, const wchar_t *__restrict, size_t);

#define EXIT_FAILURE 1
#define EXIT_SUCCESS 0

size_t __ctype_get_mb_cur_max(void);
#define MB_CUR_MAX (__ctype_get_mb_cur_max())

#define RAND_MAX (0x7fffffff)


#if defined(_POSIX_SOURCE) || defined(_POSIX_C_SOURCE) \
 || defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) \
 || defined(_BSD_SOURCE)

#define WNOHANG    1
#define WUNTRACED  2

#define WEXITSTATUS(s) (((s) & 0xff00) >> 8)
#define WTERMSIG(s) ((s) & 0x7f)
#define WSTOPSIG(s) WEXITSTATUS(s)
#define WIFEXITED(s) (!WTERMSIG(s))
#define WIFSTOPPED(s) ((short)((((s)&0xffff)*0x10001U)>>8) > 0x7f00)
#define WIFSIGNALED(s) (((s)&0xffff)-1U < 0xffu)

int posix_memalign (void **, size_t, size_t);
int setenv (const char *, const char *, int);
int unsetenv (const char *);
int mkstemp (char *);
int mkostemp (char *, int);
char *mkdtemp (char *);
int getsubopt (char **, char *const *, char **);
int rand_r (unsigned *);

#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
extern char *suboptarg;
void setproctitle(const char *, ...);
#if defined(__HyperbolaBSD__)
void setproctitle_fast(const char *, ...);
#endif
#endif
#endif

#ifdef _BSD_SOURCE
extern char *malloc_options;
uint32_t arc4random(void);
void arc4random_buf(void *, size_t);
uint32_t arc4random_uniform(uint32_t);
char *cgetcap(char *, const char *, int);
int cgetclose(void);
int cgetent(char **, char **, const char *);
int cgetfirst(char **, char **);
int cgetmatch(char *, const char *);
int cgetnext(char **, char **);
int cgetnum(char *, const char *, long *);
int cgetset(const char *);
int cgetstr(char *, const char *, char **);
int cgetusedb(int);
int cgetustr(char *, const char *, char **);
char *devname(dev_t, mode_t);
void freezero(void *, size_t);
char *getbsize(int *, long *);
const char *getprogname(void);
int heapsort(void *, size_t, size_t, int (*)(const void *, const void *));
int mergesort(void *, size_t, size_t, int (*)(const void *, const void *));
int radixsort(const unsigned char **, int, const unsigned char *, unsigned int);
void *recallocarray(void *, size_t, size_t, size_t);
void setprogname(const char *);
int sradixsort(const unsigned char **, int, const unsigned char *, unsigned int);
#endif

#if defined(_XOPEN_SOURCE) || defined(_GNU_SOURCE) \
 || defined(_BSD_SOURCE)
char *realpath (const char *__restrict, char *__restrict);
long int random (void);
void srandom (unsigned int);
char *initstate (unsigned int, char *, size_t);
char *setstate (char *);
int putenv (char *);
int posix_openpt (int);
int grantpt (int);
int unlockpt (int);
char *ptsname (int);
char *l64a (long);
long a64l (const char *);
void setkey (const char *);
double drand48 (void);
double erand48 (unsigned short [3]);
long int lrand48 (void);
long int nrand48 (unsigned short [3]);
long mrand48 (void);
long jrand48 (unsigned short [3]);
void srand48 (long);
unsigned short *seed48 (unsigned short [3]);
void lcong48 (unsigned short [7]);
#endif

#ifdef _BSD_SOURCE
#define lcong48_deterministic(p) lcong48(p)
#define seed48_deterministic(xseed) seed48(xseed)
#define srand_deterministic(seed) srand(seed)
#define srand48_deterministic(seed) srand48(seed)
#define srandom_deterministic(seed) srandom(seed)

void lcong48_non_deterministic (unsigned short [7]);
unsigned short *seed48_non_deterministic (unsigned short [3]);
void srand_non_deterministic (unsigned);
void srand48_non_deterministic (long);
void srandom_non_deterministic (unsigned int);

void srandomdev (void); // non_deterministic
#endif

#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#include <alloca.h>
char *mktemp (char *);
int mkstemps (char *, int);
int mkostemps (char *, int, int);
void *valloc (size_t);
void *memalign(size_t, size_t);
int getloadavg(double *, int);
int clearenv(void);
#define WCOREDUMP(s) ((s) & 0x80)
#define WIFCONTINUED(s) ((s) == 0xffff)
void *reallocarray (void *, size_t, size_t);
void qsort_r (void *, size_t, size_t, int (*)(const void *, const void *, void *), void *);
#endif

#ifdef _GNU_SOURCE
int ptsname_r(int, char *, size_t);
char *ecvt(double, int, int *, int *);
char *fcvt(double, int, int *, int *);
char *gcvt(double, int, char *);
char *secure_getenv(const char *);
struct __locale_struct;
float strtof_l(const char *__restrict, char **__restrict, struct __locale_struct *);
double strtod_l(const char *__restrict, char **__restrict, struct __locale_struct *);
long double strtold_l(const char *__restrict, char **__restrict, struct __locale_struct *);
#endif

#if defined(_LARGEFILE64_SOURCE)
#define mkstemp64 mkstemp
#define mkostemp64 mkostemp
#if defined(_GNU_SOURCE) || defined(_BSD_SOURCE)
#define mkstemps64 mkstemps
#define mkostemps64 mkostemps
#endif
#endif

#ifdef __cplusplus
}
#endif

#endif
