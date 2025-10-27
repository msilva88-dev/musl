#include <stdlib.h>
#include <string.h>

#ifdef _BSD_SOURCE
char *suboptarg;
#endif

int getsubopt(char **opt, char *const *keys, char **val)
{
	char *s = *opt;
	int i;

	*val = NULL;
#ifdef _BSD_SOURCE
	if (!s || !*s) {
		suboptarg = NULL;
		return -1;
	}
	while (*s == ' ' || *s == '\t') s++;
	suboptarg = s;
	char *p;
	for (p = s; *p; p++) {
		if (*p == ',' || *p == ' ' || *p == '\t') break;
	}
	*opt = p;
	if (**opt) *(*opt)++ = '\0';
	if (*s == '\0') {
		suboptarg = NULL;
		return -1;
	}
#else
	*opt = strchr(s, ',');
	if (*opt) *(*opt)++ = 0;
	else *opt = s + strlen(s);
#endif

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
