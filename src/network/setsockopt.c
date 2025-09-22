#include <sys/socket.h>
#include <sys/time.h>
#include <errno.h>
#include "syscall.h"

#if defined(__linux__)
#define IS32BIT(x) !((x)+0x80000000ULL>>32)
#define CLAMP(x) (int)(IS32BIT(x) ? (x) : 0x7fffffffU+((0ULL+(x))>>63))
#endif

int setsockopt(int fd, int level, int optname, const void *optval, socklen_t optlen)
{
#if defined(__linux__)
	const struct timeval *tv;
	time_t s;
	suseconds_t us;
#endif

	int r = __socketcall(setsockopt, fd, level, optname, optval, optlen, 0);

#if defined(__linux__)
	if (r==-ENOPROTOOPT) switch (level) {
	case SOL_SOCKET:
		switch (optname) {
		case SO_RCVTIMEO:
		case SO_SNDTIMEO:
			if (SO_RCVTIMEO == SO_RCVTIMEO_OLD) break;
			if (optlen < sizeof *tv) return __syscall_ret(-EINVAL);
			tv = optval;
			s = tv->tv_sec;
			us = tv->tv_usec;
			if (!IS32BIT(s)) return __syscall_ret(-ENOTSUP);

			if (optname==SO_RCVTIMEO) optname=SO_RCVTIMEO_OLD;
			if (optname==SO_SNDTIMEO) optname=SO_SNDTIMEO_OLD;

			r = __socketcall(setsockopt, fd, level, optname,
				((long[]){s, CLAMP(us)}), 2*sizeof(long), 0);
			break;
		case SO_TIMESTAMP:
		case SO_TIMESTAMPNS:
			if (SO_TIMESTAMP == SO_TIMESTAMP_OLD) break;
			if (optname==SO_TIMESTAMP) optname=SO_TIMESTAMP_OLD;
			if (optname==SO_TIMESTAMPNS) optname=SO_TIMESTAMPNS_OLD;
			r = __socketcall(setsockopt, fd, level,
				optname, optval, optlen, 0);
			break;
		}
	}
#endif
	return __syscall_ret(r);
}
