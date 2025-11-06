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
#endif

UNUSED_A void endservent_r(struct servent_data *data)
{
	if (!data) return;
#ifdef NO_HARDCODED
	if (data->fp && !data->stayopen) fclose(data->fp), data->fp = NULL;
	if (data->line) free(data->line), data->line = NULL;
	if (data->aliases) {
		for (int i = 0; data->aliases[i]; i++) free(data->aliases[i]);
		free(data->aliases);
		data->aliases = NULL;
	}
	data->maxaliases = 0;
	data->stayopen = 0;
#endif
}

UNUSED_A void setservent_r(int stayopen UNUSED_A, struct servent_data *data)
{
	if (!data) return;
#ifndef NO_HARDCODED
	(void)stayopen;
#else
	if (data->fp) rewind(data->fp);
	else data->fp = fopen(_PATH_SERVICES, "re");
	data->stayopen = stayopen != 0;
#endif
}

int getservent_r(struct servent *s, struct servent_data *data)
{
	if (!data || !s) return -1;
#ifdef NO_HARDCODED
	char *hash, *saveptr, *tok, *name, *protoptr, *proto, *endp;
	size_t len = 0;
	ssize_t n;
	long port;
	int i;
	if (!data->fp && !(data->fp = fopen(_PATH_SERVICES, "re"))) return -1;

	while ((n = getline(&data->line, &len, data->fp)) != -1) {
		if (n == 0 || data->line[0] == '#' || data->line[0] == '\n') continue;
		if (data->line[n-1] == '\n') data->line[n-1] = '\0';
		if ((hash = strchr(data->line, '#'))) *hash = '\0';
		if (!(tok = strtok_r(data->line, " \t", &saveptr))) continue;
		name = strdup(tok);
		if (!(tok = strtok_r(NULL, "/", &saveptr))) free(name), continue;
		port = strtol(tok, &endp, 10);
		if (*endp != '\0' || port < 0 || port > USHRT_MAX) free(name), continue;
		if (!(protoptr = strtok_r(NULL, " \t", &saveptr))) free(name), continue;
		if (!(proto = strdup(protoptr))) free(name), break;
		free(s->s_name);
		free(s->s_proto);
		s->s_name = name;
		s->s_proto = proto;
		s->s_port = htons((uint16_t)port);
		if (!data->aliases) {
			data->aliases = calloc((data->maxaliases = 10), sizeof(char *));
			if (!data->aliases) break;
		} else {
			for (i = 0; data->aliases[i]; i++) free(data->aliases[i]);
			memset(data->aliases, 0, data->maxaliases * sizeof(char *));
		}
		for (i = 0; (tok = strtok_r(NULL, " \t", &saveptr)) && i < data->maxaliases - 1; i++) {
			data->aliases[i] = strdup(tok);
		}
		data->aliases[i] = NULL;
		s->s_aliases = data->aliases;

		return 0;
	}
#endif
	return -1;
}
