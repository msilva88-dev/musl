#include <sys/socket.h>
#include <limits.h>
#include <string.h>
#include <errno.h>
#include "syscall.h"

ssize_t sendmsg(int fd, const struct msghdr *msg, int flags)
{
#if LONG_MAX > INT_MAX
	struct msghdr h;
	/* Kernels before 2.6.38 set SCM_MAX_FD to 255, allocate enough
	 * space to support an SCM_RIGHTS ancillary message with 255 fds.
	 * Kernels since 2.6.38 set SCM_MAX_FD to 253. */
	struct cmsghdr chbuf[CMSG_SPACE(255*sizeof(int))/sizeof(struct cmsghdr)+1], *c;
	if (msg) {
		h = *msg;
#if defined(__linux__)
		h.__pad1 = h.__pad2 = 0;
#endif
		msg = &h;
		if (h.msg_controllen) {
			if (h.msg_controllen > sizeof chbuf) {
				errno = ENOMEM;
				return -1;
			}
			memcpy(chbuf, h.msg_control, h.msg_controllen);
			h.msg_control = chbuf;
			for (c=CMSG_FIRSTHDR(&h); c; c=CMSG_NXTHDR(&h,c))
				c->__pad1 = 0;
		}
	}
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return syscall_cp(SYS_sendmsg, fd, msg, flags);
#elif defined(__linux__)
	return socketcall_cp(sendmsg, fd, msg, flags, 0, 0, 0);
#endif
}
