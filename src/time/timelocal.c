#define _BSD_SOURCE
#include <time.h>

time_t timelocal(struct tm *tm)
{
	if (tm) tm->tm_isdst = -1;
	return mktime(tm);
}
