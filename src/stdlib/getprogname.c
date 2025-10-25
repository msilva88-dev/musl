#define _BSD_SOURCE
#include <stdlib.h>
#include "libc.h"

const char *getprogname(void)
{
	return __progname;
}
