#define _BSD_SOURCE
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#include "time_impl.h"

static char std_name[TZNAME_MAX+1];
static char dst_name[TZNAME_MAX+1];

static int dst_off;

static const unsigned char *zi, *trans, *index, *types, *abbrevs, *abbrevs_end;
static size_t map_size;

static char old_tz_buf[32];
static char *old_tz = old_tz_buf;

static volatile int lock[1];

#define VEC(...) ((const unsigned char[]){__VA_ARGS__})

static inline uint32_t zi_read32(const unsigned char *z)
{
	return (unsigned)z[0]<<24 | z[1]<<16 | z[2]<<8 | z[3];
}

static size_t zi_dotprod(const unsigned char *z, const unsigned char *v, size_t n)
{
	size_t y;
	uint32_t x;
	for (y=0; n; n--, z+=4, v++) {
		x = zi_read32(z);
		y += x * *v;
	}
	return y;
}

static void do_tzsetwall(void)
{
	const char *s;
	const unsigned char *map = 0;
	size_t i;

	s = "/etc/localtime";

	if (old_tz && !strcmp(s, old_tz)) return;

	if (zi) __munmap((void *)zi, map_size);

	/* Cache the old value of TZ to check if it has changed. Avoid
	 * free so as not to pull it into static programs. Growth
	 * strategy makes it so free would have minimal benefit anyway. */
	i = strlen(s);
	if (i > PATH_MAX+1) s = __utc, i = 3;
	memcpy(old_tz, s, i+1);

	map = __map_file(s, &map_size);
	if (map && (map_size < 44 || memcmp(map, "TZif", 4))) {
		__munmap((void *)map, map_size);
		map = 0;
		s = __utc;
	}

	zi = map;
	if (map) {
		int scale = 2;
		if (map[4]!='1') {
			size_t skip = zi_dotprod(zi+20, VEC(1,1,8,5,6,1), 6);
			trans = zi+skip+44+44;
			scale++;
		} else {
			trans = zi+44;
		}
		index = trans + (zi_read32(trans-12) << scale);
		types = index + zi_read32(trans-12);
		abbrevs = types + 6*zi_read32(trans-8);
		abbrevs_end = abbrevs + zi_read32(trans-4);
		if (zi[map_size-1] == '\n') {
			for (s = (const char *)zi+map_size-2; *s!='\n'; s--);
			s++;
		} else {
			const unsigned char *p;
			tzname[0] = tzname[1] = 0;
			daylight = timezone = dst_off = 0;
			for (p=types; p<abbrevs; p+=6) {
				if (!p[4] && !tzname[0]) {
					tzname[0] = (char *)abbrevs + p[5];
					timezone = -zi_read32(p);
				}
				if (p[4] && !__tzname[1]) {
					tzname[1] = (char *)abbrevs + p[5];
					dst_off = -zi_read32(p);
					daylight = 1;
				}
			}
			if (!tzname[0]) tzname[0] = tzname[1];
			if (!tzname[0]) tzname[0] = (char *)__utc;
			if (!daylight) {
				tzname[1] = tzname[0];
				dst_off = timezone;
			}
			return;
		}
	}

	tzname[0] = std_name;
	tzname[1] = dst_name;
	if (dst_name[0]) {
		daylight = 1;
		dst_off = timezone - 3600;
	} else {
		daylight = 0;
		dst_off = timezone;
	}
}

void tzsetwall(void) {
	LOCK(lock);
	do_tzsetwall();
	UNLOCK(lock);
}
