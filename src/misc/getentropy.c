#define _BSD_SOURCE
#include <unistd.h>
#if defined(__linux__)
#include <sys/random.h>
#endif
#include <pthread.h>
#include <errno.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include "syscall.h"
#endif

int getentropy(void *buffer, size_t len)
{
	int cs, ret = 0;
	char *pos = buffer;

	if (len > 256) {
		errno = EIO;
		return -1;
	}

	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);

	while (len) {
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		ret = syscall(SYS_getentropy, pos, len);
#elif defined(__linux__)
		ret = getrandom(pos, len, 0);
#endif
		if (ret < 0) {
			if (errno == EINTR) continue;
			else break;
		}
		pos += ret;
		len -= ret;
		ret = 0;
	}

	pthread_setcancelstate(cs, 0);

	return ret;
}
