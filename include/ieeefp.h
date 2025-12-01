#ifndef _IEEEFP_H
#define _IEEEFP_H

#ifdef __cplusplus
extern "C" {
#endif

#include <fenv.h>

typedef int fp_except;
typedef int fp_rnd;

#define FP_X_DNML 0 /* This does not exist an equivalent in fenv.h */
#define FP_X_DZ FE_DIVBYZERO
#define FP_X_IMP FE_INEXACT
#define FP_X_INV FE_INVALID
#define FP_X_OFL FE_OVERFLOW
#define FP_X_UFL FE_UNDERFLOW

#define FP_RN FE_TONEAREST
#define FP_RZ FE_TOWARDZERO
#define FP_RP FE_UPWARD
#define FP_RM FE_DOWNWARD

static inline fp_except fpgetmask(void)
{
	return fegetexcept();
}

static inline fp_except fpsetmask(fp_except mask)
{
	fp_except old = fegetexcept();
	fedisableexcept(~mask & FE_ALL_EXCEPT);
	feenableexcept(mask & FE_ALL_EXCEPT);
	return old;
}

static inline fp_except fpgetsticky(void)
{
	return fetestexcept(FE_ALL_EXCEPT);
}

static inline fp_except fpsetsticky(fp_except sticky)
{
	fp_except old = fetestexcept(FE_ALL_EXCEPT);
	feclearexcept(sticky);
	return old;
}

static inline fp_rnd fpgetround(void)
{
	return fegetround();
}

static inline fp_rnd fpsetround(fp_rnd r)
{
	fp_rnd old = fegetround();
	fesetround(r);
	return old;
}

#ifdef __cplusplus
}
#endif

#endif /* _IEEEFP_H */
