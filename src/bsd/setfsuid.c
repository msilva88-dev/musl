#include <unistd.h>
#include <errno.h>
#include <sys/types.h>

// setfsuid_wrapper

int setfsuid(uid_t uid)
{
	if (seteuid(uid) < 0) {
		return -errno;
	}

	return 0;
}
