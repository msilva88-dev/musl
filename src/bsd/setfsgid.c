#include <unistd.h>
#include <errno.h>
#include <sys/types.h>

// setfsgid_wrapper

int setfsgid(gid_t gid)
{
	if (setegid(gid) < 0) {
		return -errno;
	}

	return 0;
}
