#include <stddef.h>
#include <stdlib.h>

/* Minimal stage-1 __assert_fail: keep it simple, just abort(). */
void __assert_fail(const char *expr, const char *file, int line, const char *fn)
{
	(void)expr; (void)file; (void)line; (void)fn;
	abort();
}
