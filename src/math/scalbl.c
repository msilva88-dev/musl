#define _BSD_SOURCE
#include <math.h>
#include <float.h>
#include <limits.h>

static const long double pow2_table[16] = {
	1.0L,
	1.0442737824274138L, // 2^(1/16)
	1.0905077326652577L, // 2^(2/16)
	1.1387886347566916L, // 2^(3/16)
	1.189207115002721L, // 2^(4/16)
	1.241857812073484L, // 2^(5/16)
	1.2968395546510096L, // 2^(6/16)
	1.3542555469368927L, // 2^(7/16)
	1.4142135623730951L, // 2^(8/16)
	1.4768261459394993L, // 2^(9/16)
	1.541980963927699L, // 2^(10/16)
	1.609893072746681L, // 2^(11/16)
	1.680792340097184L, // 2^(12/16)
	1.754887502163468L, // 2^(13/16)
	1.832980710832437L, // 2^(14/16)
	1.9152065613971474L // 2^(15/16)
};

long double scalbl(long double x, long double n)
{
	if (isnan(x) || isnan(n)) return x * n;
	if (!isfinite(n)) {
		if (n > 0.0L) return x * n;
		else return x / (-n);
	}
	if (x == 0.0L) return x;

	long int int_part;
	long double frac_part = modfl(n, &int_part);

	if (int_part > 65000) int_part = 65000;
	else if (int_part < -65000) int_part = -65000;

	long double result = scalbnl(x, int_part);

	if (frac_part != 0.0L) {
		int index = (int)(frac_part * 16.0L);
		long double delta = frac_part - (long double)index / 16.0L;
		long double t = delta * M_LN2L;
		long double t2 = t * t;
		long double t3 = t2 * t;
		long double poly = 1.0L + t + t2/2.0L + t3/6.0L;
		result *= pow2_table[index] * poly;
	}

	return result;
}
