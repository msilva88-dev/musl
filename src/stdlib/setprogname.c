#define _BSD_SOURCE

#define __NEED_uintptr_t

#include <bits/alltypes.h>

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include "libc.h"

static char __progname_safe[NAME_MAX];

void setprogname(const char *name)
{
	if (!name) return;

	const char *base = strrchr(name, '/');
	if (base) base++;
	else base = name;

	if (
		(uintptr_t)base >= (uintptr_t)&__progname_safe
		&& (uintptr_t)base < (uintptr_t)&__progname_safe + sizeof(__progname_safe)
	) {
		size_t len = strlen(base);
		if (len >= NAME_MAX) len = NAME_MAX - 1;
		memcpy(__progname_safe, base, len);
		__progname_safe[len] = '\0';
		__progname = __progname_safe;
	} else {
		__progname = strdup(base);
	}
}
