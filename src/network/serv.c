#include <netdb.h>
#ifdef NO_HARDCODED
#include <arpa/inet.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#endif

#ifndef NO_HARDCODED
#ifdef __GNUC__
#define UNUSED_A __attribute__((__unused__))
#else
#define UNUSED_A
#endif
#else
#define UNUSED_A
static FILE *fp;
static char **aliases;
static int maxaliases;
static int stayopen_flag;
static char *line;
#endif

UNUSED_A void endservent(void)
{
#ifdef NO_HARDCODED
	if (fp && !stayopen_flag) fclose(fp), fp = NULL;
	if (line) free(line), line = NULL;
	if (aliases) {
		for (int i = 0; aliases[i]; i++) free(aliases[i]);
		free(aliases);
		aliases = NULL;
	}
	maxaliases = 0;
	stayopen_flag = 0;
#endif
}

UNUSED_A void setservent(int stayopen UNUSED_A)
{
#ifndef NO_HARDCODED
	(void)stayopen;
#else
	if (fp) rewind(fp);
	else fp = fopen(_PATH_SERVICES, "re");
	stayopen_flag = stayopen != 0;
#endif
}

struct servent *getservent(void)
{
#ifdef NO_HARDCODED
	static struct servent s;
	char *hash, *saveptr, *tok, *name, *protoptr, *proto, *endp;
	size_t len = 0;
	ssize_t n;
	long port;
	int i;
	if (!fp && !(fp = fopen(_PATH_SERVICES, "re"))) return NULL;

	while ((n = getline(&line, &len, fp)) != -1) {
		if (n == 0 || line[0] == '#' || line[0] == '\n') continue;
		if (line[n-1] == '\n') line[n-1] = '\0';
		if ((hash = strchr(line, '#'))) *hash = '\0';
		if (!(tok = strtok_r(line, " \t", &saveptr))) continue;
		name = strdup(tok);
		if (!(tok = strtok_r(NULL, "/", &saveptr))) free(name), continue;
		port = strtol(tok, &endp, 10);
		if (*endp != '\0' || port < 0 || port > USHRT_MAX) free(name), continue;
		if (!(protoptr = strtok_r(NULL, " \t", &saveptr))) free(name), continue;
		if (!(proto = strdup(protoptr))) free(name), break;
		free(s.s_name);
		free(s.s_proto);
		s.s_name = name;
		s.s_proto = proto;
		s.s_port = htons((uint16_t)port);
		if (!aliases) {
			aliases = calloc((maxaliases = 5), sizeof(char *));
			if (!aliases) break;
		} else {
			for (i = 0; aliases[i]; i++) free(aliases[i]);
			memset(aliases, 0, maxaliases * sizeof(char *));
		}
		for (i = 0; (tok = strtok_r(NULL, " \t", &saveptr)) && i < maxaliases - 1; i++) {
			aliases[i] = strdup(tok);
		}
		aliases[i] = NULL;
		s.s_aliases = aliases;

		return &s;
	}
#endif
	return 0;
}
