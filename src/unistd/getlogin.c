#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <errno.h>
#include <limits.h>
#endif
#include <unistd.h>
#if defined(__linux__)
#include <stdlib.h>
#endif

char *getlogin(void)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	static _Thread_local char name[LOGIN_NAME_MAX];
	int ret = syscall(SYS_getlogin_r, name, sizeof(name));

	if (ret || name[0] == '\0') {
		errno = ret ? ret : ENOENT;
		return NULL;
	}

	return name;
#elif defined(__linux__)
	return getenv("LOGNAME");
#endif
}
