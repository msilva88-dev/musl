#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <pthread.h>
#include <stdlib.h>
#endif
#include <unistd.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#elif defined(__linux__)
#include <stdlib.h>
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static pthread_key_t key;
static pthread_once_t key_once = PTHREAD_ONCE_INIT;

static void make_key(void) {
	pthread_key_create(&key, free);
}
#endif

char *getlogin(void)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	pthread_once(&key_once, make_key);
	char *name = pthread_getspecific(key);

	if (!name) {
		name = malloc(LOGIN_NAME_MAX);
		if (!name) return NULL;
		pthread_setspecific(key, name);
	}
	int ret = syscall(SYS_getlogin_r, name, LOGIN_NAME_MAX);

	if (ret || name[0] == '\0') {
		errno = ret ? ret : ENOENT;
		return NULL;
	}

	return name;
#elif defined(__linux__)
	return getenv("LOGNAME");
#endif
}
