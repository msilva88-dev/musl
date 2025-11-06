#define _BSD_SOURCE
#include <netdb.h>
#include <string.h>
#ifdef NO_HARDCODED
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#endif

#ifndef NO_HARDCODED
/* do we really need all these?? */

#ifdef __GNUC__
#define UNUSED_A __attribute__((unused))
#else
#define UNUSED_A
#endif

static const unsigned char protos[] = {
	"\000ip\0"
	"\001icmp\0"
	"\002igmp\0"
	"\003ggp\0"
	"\004ipencap\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"\005st2\0"
#elif defined(__linux__)
	"\005st\0"
#endif
	"\006tcp\0"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	"\008egp\0"
	"\012pup\0"
	"\017udp\0"
	"\020hmp\0"
	"\022xns-idp\0"
	"\027rdp\0"
	"\029iso-tp4\0"
	"\036xtp\0"
	"\037ddp\0"
	"\038idpr-cmtp\0"
	"\041ipv6\0"
	"\043ipv6-route\0"
	"\044ipv6-frag\0"
	"\045idrp\0"
	"\046rsvp\0"
	"\047gre\0"
	"\050esp\0"
	"\051ah\0"
	"\057skip\0"
	"\058ipv6-icmp\0"
	"\059ipv6-nonxt\0"
	"\060ipv6-opts\0"
	"\081vmtp\0"
	"\089ospf\0"
	"\094ipip\0"
	"\098encap\0"
	"\103pim\0"
	"\255raw"
#elif defined(__linux__)
	"\010egp\0"
	"\014pup\0"
	"\021udp\0"
	"\024hmp\0"
	"\026xns-idp\0"
	"\033rdp\0"
	"\035iso-tp4\0"
	"\044xtp\0"
	"\045ddp\0"
	"\046idpr-cmtp\0"
	"\051ipv6\0"
	"\053ipv6-route\0"
	"\054ipv6-frag\0"
	"\055idrp\0"
	"\056rsvp\0"
	"\057gre\0"
	"\062esp\0"
	"\063ah\0"
	"\071skip\0"
	"\072ipv6-icmp\0"
	"\073ipv6-nonxt\0"
	"\074ipv6-opts\0"
	"\111rspf\0" // Linux specific
	"\121vmtp\0"
	"\131ospf\0"
	"\136ipip\0"
	"\142encap\0"
	"\147pim\0"
	"\377raw"
#endif
};
#else
#define UNUSED_A
#endif

void endprotoent_r(struct protoent_data *data)
{
	if (!data) return;
#ifndef NO_HARDCODED
	data->idx = 0;
#else
	if (data->fp && !data->stayopen) {
		fclose(data->fp);
		data->fp = NULL;
	}
	free(data->line);
	data->line = NULL;
	if (data->aliases) {
		for (int i = 0; data->aliases[i]; i++) free(data->aliases[i]);
		free(data->aliases);
		data->aliases = NULL;
	}
	data->maxaliases = 0;
	data->stayopen = 0;
#endif
}

void setprotoent_r(int stayopen UNUSED_A, struct protoent_data *data)
{
	if (!data) return;
#ifndef NO_HARDCODED
	(void)stayopen;
	data->idx = 0;
#else
	if (data->fp) rewind(data->fp);
	else data->fp = fopen(_PATH_PROTOCOLS, "re");
	data->stayopen = stayopen != 0;
#endif
}

int getprotoent_r(struct protoent *p, struct protoent_data *data)
{
	int ret = 0;
	if (!data || !p) return -1;
#ifndef NO_HARDCODED
	static const char *aliases;
	if (data->idx >= sizeof protos) return -1;
	p->p_proto = protos[data->idx];
	p->p_name = (char *)&protos[data->idx+1];
	p->p_aliases = (char **)&aliases;
	data->idx += strlen(p->p_name) + 2;
#else
	char *lline = NULL, *hash, *saveptr, *tok, *name, *endp;
	size_t len = 0;
	ssize_t n;
	long num;
	int i;
	if (!data->fp && !(data->fp = fopen(_PATH_PROTOCOLS, "re"))) return -1;

	while ((n = getline(&lline, &len, data->fp)) != -1) {
		if (n == 0 || lline[0] == '#' || lline[0] == '\n') continue;
		if (lline[n-1] == '\n') lline[n-1] = '\0';
		if ((hash = strchr(lline, '#'))) *hash = '\0';
		if (!(tok = strtok_r(lline, " \t", &saveptr))) continue;
		memset(p, 0, sizeof(*p));
		name = strdup(tok);
		if (!(tok = strtok_r(NULL, " \t", &saveptr))) free(name), continue;
		num = strtol(tok, &endp, 10);
		if (*endp != '\0' || num < 0 || num > INT_MAX) free(name), continue;
		p->p_name = name;
		p->p_proto = (int)num;
		if (!data->aliases) {
			data->aliases = calloc((data->maxaliases = 5), sizeof(char *));
			if (!data->aliases) break;
		} else {
			for (i = 0; data->aliases[i]; i++) free(data->aliases[i]);
			memset(data->aliases, 0, data->maxaliases * sizeof(char *));
		}
		for (i = 0; (tok = strtok_r(NULL, " \t", &saveptr)) && i < data->maxaliases - 1; i++) {
			data->aliases[i] = strdup(tok);
		}
		data->aliases[i] = NULL;
		p->p_aliases = data->aliases;
		free(data->line);
		data->line = strdup(lline);
		free(lline);

		return ret;
	}

	free(lline);
	ret = -1;
#endif
	return ret;
}

int getprotobyname_r(const char *name, struct protoent *p, struct protoent_data *data)
{
	int ret = 0;
	if (!name || !data || !p) return -1;
#ifndef NO_HARDCODED
	data->idx = 0;
	do ret = getprotoent_r(p, data);
	while (ret == 0 && strcmp(name, p->p_name));
#else
	int found = 0;
	setprotoent_r(data->stayopen, data);
	do {
		if ((ret = getprotoent_r(p, data)) != 0) break;
		if (strcmp(name, p->p_name) == 0) break;
		for (char **alias = p->p_aliases; *alias; alias++) {
			if (strcmp(*alias, name) == 0) found = 1, break;
		}
		if (found) break;
	} while (1);
	if (data->fp && !data->stayopen) endprotoent_r(data);
#endif
	return ret;
}

int getprotobynumber_r(int num, struct protoent *p, struct protoent_data *data)
{
	int ret = 0;
	if (!data || !p) return -1;
#ifndef NO_HARDCODED
	data->idx = 0;
#else
	setprotoent_r(data->stayopen, data);
#endif
	do ret = getprotoent_r(p, data);
	while (ret == 0 && p->p_proto != num);
#ifdef NO_HARDCODED
	if (data->fp && !data->stayopen) endprotoent_r(data);
#endif
	return ret;
}
