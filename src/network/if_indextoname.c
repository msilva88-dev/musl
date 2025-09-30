#define _GNU_SOURCE
#include <net/if.h>
#include <sys/socket.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <stdbool.h>
#include <stdlib.h>
#elif defined(__linux__)
#include <sys/ioctl.h>
#endif
#include <string.h>
#include <errno.h>
#include "syscall.h"

char *if_indextoname(unsigned index, char *name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct if_nameindex *ifn2i = if_nameindex(), *ifn2ip = ifn2i;
	bool found = false;

	if (!ifn2i) return 0;
	while (ifn2ip->if_index) {
		if (ifn2ip->if_index == index) {
			strlcpy(name, ifn2ip->if_name, IF_NAMESIZE);
			found = true;
			break;
		}
		ifn2ip++;
	}
	if_freenameindex(ifn2i);
	if (!found) {
		errno = ENXIO;
		return NULL;
	}
	return name;
#elif defined(__linux__)
	struct ifreq ifr;
	int fd, r;

	if ((fd = socket(AF_UNIX, SOCK_DGRAM|SOCK_CLOEXEC, 0)) < 0) return 0;
	ifr.ifr_ifindex = index;
	r = ioctl(fd, SIOCGIFNAME, &ifr);
	__syscall(SYS_close, fd);
	if (r < 0) {
		if (errno == ENODEV) errno = ENXIO;
		return 0;
	}
	return strncpy(name, ifr.ifr_name, IF_NAMESIZE);
#endif
}
