#ifndef _FENV_H
#define _FENV_H

#ifdef __cplusplus
extern "C" {
#endif

#include <bits/fenv.h>

int feclearexcept(int);
int fegetexceptflag(fexcept_t *, int);
int feraiseexcept(int);
int fesetexceptflag(const fexcept_t *, int);
int fetestexcept(int);

int fegetround(void);
int fesetround(int);

int fegetenv(fenv_t *);
int feholdexcept(fenv_t *);
int fesetenv(const fenv_t *);
int feupdateenv(const fenv_t *);

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#ifdef _BSD_SOURCE
int feenableexcept(int);
int fedisableexcept(int);
int fegetexcept(void);
#endif
#endif

#ifdef __cplusplus
}
#endif
#endif
