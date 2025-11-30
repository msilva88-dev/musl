#define _BSD_SOURCE
#include <stdlib.h>
#include <errno.h>
#include <limits.h>
#include <ctype.h>
#include <string.h>

static const char too_large[] = "too large";
static const char too_small[] = "too small";
static const char invalid[] = "invalid";

/*
 * strtonum - safely convert a string to a long long with min/max bounds
 * Input:
 *   nptr   - input string
 *   minval - minimum allowed value
 *   maxval - maximum allowed value
 *   errstr - pointer to where (on error) an error string will be stored,
 *            or NULL if not needed
 */
long long strtonum(const char *nptr, long long minval, long long maxval, const char **errstr)
{
	long long val = 0;
	char *endp;
	int saved_errno = errno;

	if (errstr) *errstr = NULL;
	errno = 0;

	/* minval > maxval: error */
	if (minval > maxval) {
		if (errstr) *errstr = invalid;
		errno = EINVAL;
		return 0;
	}

	/* Skip leading whitespace (isspace(3)) */
	while (isspace((unsigned char)*nptr))
        ++nptr;

	if (*nptr == '\0') {
		/* Empty or whitespace-only string */
		if (errstr) *errstr = invalid;
		errno = EINVAL;
		return 0;
	}

	val = strtoll(nptr, &endp, 10);

	/* If no conversion performed or trailing junk, it's invalid */
	if (nptr == endp || *endp != '\0') {
		if (errstr) *errstr = invalid;
		errno = EINVAL;
		return 0;
	}

	/* Range errors detected by strtoll */
	if (errno == ERANGE || val < minval || val > maxval) {
		if (val < minval || (errno == ERANGE && val == LLONG_MIN)) {
			if (errstr) *errstr = too_small;
			errno = ERANGE;
			return 0;
		}

		if (val > maxval || (errno == ERANGE && val == LLONG_MAX)) {
			if (errstr) *errstr = too_large;
			errno = ERANGE;
			return 0;
		}
	}

	/* Valid range, return value, *errstr = NULL */
	errno = saved_errno;
	return val;
}
