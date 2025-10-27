#include <stdlib.h>
#include <string.h>

char *suboptarg;

int getsubopt(char **opt, char *const *keys, char **val)
{
	char *s = *opt;
	int i;

	*val = NULL;
	if (!s || !*s) {
		suboptarg = NULL;
		return -1;
	}
	while (*s == ' ' || *s == '\t') s++;
	suboptarg = s;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	char *p;
	for (p = s; *p; p++) {
		if (*p == ',' || *p == ' ' || *p == '\t') break;
	}
	*opt = p;
	if (**opt) *(*opt)++ = '\0';
#elif defined(__linux__)
	*opt = strchr(s, ',');
	if (*opt) *(*opt)++ = 0;
	else *opt = s + strlen(s);
#endif
	if (*s == '\0') {
		suboptarg = NULL;
		return -1;
	}

	for (i=0; keys[i]; i++) {
		size_t l = strlen(keys[i]);
		if (strncmp(keys[i], s, l)) continue;
		if (s[l] == '=')
			*val = s + l + 1;
		else if (s[l]) continue;
		return i;
	}
	return -1;
}
