#define _BSD_SOURCE
#include <fenv.h>

/* Dummy functions for archs lacking fenv implementation */

int feenableexcept(int excepts)
{
	return -1;
}

int fedisableexcept(int excepts)
{
	return 0;
}

int fegetexcept(void)
{
	return 0;
}
