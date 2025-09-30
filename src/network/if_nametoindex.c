#define _GNU_SOURCE
#include <net/if.h>
#include <sys/socket.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <errno.h>
#include <stdlib.h>
#elif defined(__linux__)
#include <sys/ioctl.h>
#endif
#include <string.h>
#include "syscall.h"

unsigned if_nametoindex(const char *name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct if_nameindex *ifn2i = if_nameindex(), *ifn2ip = ifn2i;
	unsigned int i = 0;

	if (!ifn2i) return 0;
	while (ifn2ip->if_index) {
		if (strcmp(ifn2ip->if_name, name)) {
			i = ifn2ip->if_index;
			break;
		}
		ifn2ip++;
	}
	if_freenameindex(ifn2i);
	if (!i) errno = ENXIO;
	return i;
#elif defined(__linux__)
	struct ifreq ifr;
	int fd, r;

	if ((fd = socket(AF_UNIX, SOCK_DGRAM|SOCK_CLOEXEC, 0)) < 0) return 0;
	strncpy(ifr.ifr_name, name, sizeof ifr.ifr_name);
	r = ioctl(fd, SIOCGIFINDEX, &ifr);
	__syscall(SYS_close, fd);
	return r < 0 ? 0 : ifr.ifr_ifindex;
#endif
}
