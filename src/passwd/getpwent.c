#include "pwf.h"

static FILE *f;
static char *line;
static struct passwd pw;
static size_t size;
static int stayopen_flag = 0;

int setpassent(int);

void setpwent()
{
	//if (f) fclose(f);
	//f = 0;
	setpassent(0);
}

hidden void __endpwent()
{
	if (f) fclose(f);
	f = 0;
}

weak_alias(__endpwent, endpwent);

int setpassent(int stayopen)
{
	if (!f) {
		f = fopen("/etc/passwd", "rbe");
		if (!f) return 0;
	} else rewind(f);
	stayopen_flag = stayopen != 0;
	return 1;
}

struct passwd *getpwent()
{
	struct passwd *res;
	if (!f) f = fopen("/etc/passwd", "rbe");
	if (!f) return 0;
	__getpwent_a(f, &pw, &line, &size, &res);
	return res;
}

struct passwd *getpwuid(uid_t uid)
{
	struct passwd *res;
	__getpw_a(0, uid, &pw, &line, &size, &res, &f, stayopen_flag);
	return res;
}

struct passwd *getpwnam(const char *name)
{
	struct passwd *res;
	__getpw_a(name, 0, &pw, &line, &size, &res, &f, stayopen_flag);
	return res;
}
