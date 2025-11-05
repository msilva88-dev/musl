#include "pwf.h"

static FILE *f;
static char *line, **mem;
static struct group gr;
static int stayopen_flag = 0;

int setgroupent(int);

void setgrent()
{
	//if (f) fclose(f);
	//f = 0;
	setgroupent(0);
}

hidden void __endgrent()
{
	if (f) fclose(f);
	f = 0;
}

weak_alias(__endgrent, endgrent);

int setgroupent(int stayopen)
{
	if (!f) {
		f = fopen("/etc/group", "rbe");
		if (!f) return 0;
	} else rewind(f);
	stayopen_flag = stayopen != 0;
	return 1;
}

struct group *getgrent()
{
	struct group *res;
	size_t size=0, nmem=0;
	if (!f) f = fopen("/etc/group", "rbe");
	if (!f) return 0;
	__getgrent_a(f, &gr, &line, &size, &mem, &nmem, &res);
	return res;
}

struct group *getgrgid(gid_t gid)
{
	struct group *res;
	size_t size=0, nmem=0;
	__getgr_a(0, gid, &gr, &line, &size, &mem, &nmem, &res, &f, stayopen_flag);
	return res;
}

struct group *getgrnam(const char *name)
{
	struct group *res;
	size_t size=0, nmem=0;
	__getgr_a(name, 0, &gr, &line, &size, &mem, &nmem, &res, &f, stayopen_flag);
	return res;
}
