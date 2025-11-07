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

static int idx;
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
static FILE *fp;
static char **aliases;
static int maxaliases;
static int stayopen_flag;
static char *line;
#endif

void endprotoent(void)
{
#ifndef NO_HARDCODED
	idx = 0;
#else
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

void setprotoent(int stayopen UNUSED_A)
{
#ifndef NO_HARDCODED
	(void)stayopen;
	idx = 0;
#else
	if (fp) rewind(fp);
	else fp = fopen(_PATH_PROTOCOLS, "re");
	stayopen_flag = stayopen != 0;
#endif
}

struct protoent *getprotoent(void)
{
	static struct protoent p;
#ifndef NO_HARDCODED
	static const char *aliases;
	if (idx >= sizeof protos) return NULL;
	p.p_proto = protos[idx];
	p.p_name = (char *)&protos[idx+1];
	p.p_aliases = (char **)&aliases;
	idx += strlen(p.p_name) + 2;
	return &p;
#else
	char *hash, *saveptr, *tok, *name, *endp;
	size_t len = 0;
	ssize_t n;
	long proto;
	int i;
	if (!fp && !(fp = fopen(_PATH_PROTOCOLS, "re"))) return NULL;

	while ((n = getline(&line, &len, fp)) != -1) {
		if (n == 0 || line[0] == '#' || line[0] == '\n') continue;
		if (line[n-1] == '\n') line[n-1] = '\0';
		if ((hash = strchr(line, '#'))) *hash = '\0';
		if (!(tok = strtok_r(line, " \t", &saveptr))) continue;
		name = strdup(tok);
		if (!(tok = strtok_r(NULL, " \t", &saveptr))) free(name), continue;
		proto = strtol(tok, &endp, 10);
		if (*endp != '\0' || proto < 0 || proto > UCHAR_MAX) free(name), continue;
		free(p.p_name);
		p.p_name = name;
		p.p_proto = (uint8_t)proto;
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
		p.p_aliases = aliases;

		return &p;
	}

	return NULL;
#endif
}

struct protoent *getprotobyname(const char *name)
{
	struct protoent *p;
#ifndef NO_HARDCODED
	idx = 0;
	do p = getprotoent();
	while (p && strcmp(name, p->p_name));
#else
	int found = 0;
	setprotoent(stayopen_flag);
	do {
		if (!(p = getprotoent())) break;
		if (strcmp(name, p->p_name) == 0) break;
		for (char **alias = p->p_aliases; *alias; alias++) {
			if (strcmp(*alias, name) == 0) found = 1, break;
		}
		if (found) break;
	} while (1);
	if (!stayopen_flag) endprotoent();
#endif
	return p;
}

struct protoent *getprotobynumber(int num)
{
	struct protoent *p;
#ifndef NO_HARDCODED
	idx = 0;
#else
	setprotoent(stayopen_flag);
#endif
	do p = getprotoent();
	while (p && p->p_proto != num);
#ifdef NO_HARDCODED
	if (!stayopen_flag) endprotoent();
#endif
	return p;
}
