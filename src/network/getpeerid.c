#define _BSD_SOURCE
#include <sys/socket.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int getpeereid(int s, uid_t *euid, gid_t *egid)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct sockpeercred cred;
#elif defined(__linux__)
	struct ucred cred;
#endif
	socklen_t len = sizeof(cred);

	if (getsockopt(s, SOL_SOCKET, SO_PEERCRED, &cred, &len) == -1) return -1;
	if (euid) *euid = cred.uid;
	if (egid) *egid = cred.gid;
	return 0;
}
