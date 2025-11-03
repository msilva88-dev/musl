#define _BSD_SOURCE
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define MAX_LEAPS 50

static int leap_count = 0, leap_initialized = 0;

static struct leap_s {
	time_t trans; /* POSIX time of leap second */
	int corr;  /* cumulative leap seconds */
} leap_table[MAX_LEAPS];

/* pregenerated fallback (UTC time_t of leap seconds) */
static const time_t fallback_leaps[] = {
	78796800, 94694400, 126230400, 157766400, 189302400,
	220924800, 252460800, 283996800, 315532800, 347068800,
	378604800, 410140800, 441676800, 489024000, 567993600,
	631152000, 662688000, 709948800, 741484800, 773020800,
	820454400, 867715200, 915148800, 1136073600, 1230768000,
	1341100800, 1435708800, 1483228800
};

/*
 * Convert TAI-UTC timestamp (as in leap-seconds.list) to POSIX time.
 * The first leap second (1972-06-30) corresponds to TAI-UTC = 10s,
 * so we subtract 10 to align with the 1970-01-01 POSIX epoch.
 */
static inline time_t tai_to_posix(time_t tai_utc) {
	return tai_utc - 10;
}

static void __update_internal_leap_table(void) {
	if (leap_initialized) return;

	FILE *f = fopen("/usr/share/zoneinfo/leap-seconds.list", "r");
	if (f) {
		char line[256];
		int count = 0;
		while (fgets(line, sizeof line, f) && count < MAX_LEAPS) {
			if (line[0] == '#' || line[0] == '\n') continue;

			unsigned long tai_utc;
			if (sscanf(line, "%lu", &tai_utc) == 1) {
				time_t posix_time = tai_to_posix((time_t)tai_utc);
				leap_table[count].trans = posix_time;
				leap_table[count].corr = count + 1;
				count++;
			}
		}
		fclose(f);

		if (count > 0) {
			leap_count = count;
			leap_initialized = 1;
			return;
		}
	}

	/* fallback */
	leap_count = sizeof(fallback_leaps)/sizeof(fallback_leaps[0]);
	for (int i = 0; i < leap_count; i++) {
		leap_table[i].trans = fallback_leaps[i];
		leap_table[i].corr = i+1;
	}
	leap_initialized = 1;
}

static inline time_t __leap(time_t t)
{
	__update_internal_leap_table();
	for (int i = leap_count-1; i>=0; i--)
		if (t >= leap_table[i].trans) return leap_table[i].corr;
	return 0;
}

time_t time2posix(time_t t)
{
	return t - __leap(t);
}

time_t posix2time(time_t t)
{
	time_t x = t + __leap(t), y = x - __leap(x);
	while (y != t) {
		x += (y < t) ? 1 : -1;
		y = x - __leap(x);
	}
	return x;
}
