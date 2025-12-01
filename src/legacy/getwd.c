#define _BSD_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

char *getwd(char *buf)
{
	if (!buf) {
		errno = EINVAL;
		return NULL;
	}

	/* BSD getwd expects error message in buf if it fails */
	if (getcwd(buf, PATH_MAX) == NULL) {
		snprintf(buf, PATH_MAX, "getwd: %s", strerror(errno));
		return NULL;
	}
	return buf;
}
