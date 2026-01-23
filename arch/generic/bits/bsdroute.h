/*
 * Copyright (c) 1980, 1986, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* bsdroute header from OpenBSD 7.0 source code: sys/sys/net/route.h */

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#include <sys/types.h>

struct rt_metrics {
	u_int64_t rmx_pksent;
	int64_t rmx_expire;
	u_int rmx_locks, rmx_mtu, rmx_refcnt;
	/* deprecated */
	u_int rmx_hopcount, rmx_recvpipe, rmx_sendpipe, rmx_ssthresh;
	u_int rmx_rtt, rmx_rttvar, rmx_pad;
};

struct rt_msghdr {
	u_short rtm_msglen;
	u_char rtm_version, rtm_type;
	u_short rtm_hdrlen, rtm_index, rtm_tableid;
	u_char rtm_priority, rtm_mpls;
	int rtm_addrs, rtm_flags, rtm_fmask;
	pid_t rtm_pid;
	int rtm_seq, rtm_errno;
	u_int rtm_inits;
	struct rt_metrics rtm_rmx;
};

#endif
