/*
 * Copyright (c) 2010, Oracle America, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the "Oracle America, Inc." nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *   FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *   COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 *   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 *   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * xdr_rec.c, Implements TCP/IP based XDR streams with a "record marking"
 * layer above tcp (for rpc's use).
 *
 * These routines interface XDRSTREAMS to a tcp/ip connection.
 * There is a record marking layer between the xdr stream
 * and the tcp transport level.  A record is composed on one or more
 * record fragments.  A record fragment is a thirty-two bit header followed
 * by n bytes of data, where n is contained in the header.  The header
 * is represented as a htonl(uint32_t).  The high order bit encodes
 * whether or not the fragment is the last fragment of the record
 * (1 => fragment is last, 0 => more fragments to follow.
 * The other 31 bits encode the byte length of the fragment.
 */

#define _BSD_SOURCE
#include <netinet/in.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <rpc/xdr.h>
#include <rpc/auth.h>
#include <rpc/clnt.h>
#include <rpc/rpc_msg.h>
#include <rpc/svc.h>

static bool_t xdrrec_getlong(XDR *, long *);
static bool_t xdrrec_putlong(XDR *, long *);
static bool_t xdrrec_getbytes(XDR *, caddr_t, unsigned int);
static bool_t xdrrec_putbytes(XDR *, caddr_t, unsigned int);
static unsigned int xdrrec_getpos(XDR *);
static bool_t xdrrec_setpos(XDR *, unsigned int);
static int32_t *xdrrec_inline(XDR *, unsigned int);
static void xdrrec_destroy(XDR *);

/*
 * Not clear if these are used externally
 */
bool_t __xdrrec_setnonblock(XDR *, int)
	__attribute__((__deprecated__));
hidden bool_t __xdrrec_getrec(XDR *xdrs, enum xprt_stat *statp,
	bool_t expectdata);

struct ct_data;

static struct xdr_ops xdrrec_ops = {
	xdrrec_getlong,
	xdrrec_putlong,
	xdrrec_getbytes,
	xdrrec_putbytes,
	xdrrec_getpos,
	xdrrec_setpos,
	xdrrec_inline,
	xdrrec_destroy,
	NULL, /* xdrrec_control */
};

/*
 * A record is composed of one or more record fragments.
 * A record fragment is a four-byte header followed by zero to
 * 2**32-1 bytes.  The header is treated as a long unsigned and is
 * encode/decoded to the network via htonl/ntohl.  The low order 31 bits
 * are a byte count of the fragment.  The highest order bit is a boolean:
 * 1 => this fragment is the last fragment of the record,
 * 0 => this fragment is followed by more fragment(s).
 *
 * The fragment/record machinery is not general;  it is constructed to
 * meet the needs of xdr and rpc based on tcp.
 */

#define LAST_FRAG ((uint32_t)(1U << 31))

typedef struct rec_strm {
	caddr_t tcp_handle;
	/*
	 * out-goung bits
	 */
	int (*writeit)(caddr_t, caddr_t, int);
	caddr_t out_base;	/* output buffer (points to frag header) */
	caddr_t out_finger;	/* next output position */
	caddr_t out_boundry;	/* data cannot up to this address */
	uint32_t *frag_header;	/* beginning of current fragment */
	bool_t frag_sent;	/* true if buffer sent in middle of record */
	/*
	 * in-coming bits
	 */
	int (*readit)(caddr_t, caddr_t, int);
	unsigned long in_size;	/* fixed size of the input buffer */
	caddr_t in_base;
	caddr_t in_finger;	/* location of next byte to be had */
	caddr_t in_boundry;	/* can read up to this location */
	long fbtbc;		/* fragment bytes to be consumed */
	bool_t last_frag;
	unsigned int sendsize;
	unsigned int recvsize;

	bool_t nonblock;
	bool_t in_haveheader;
	uint32_t in_header;
	char *in_hdrp;
	int in_hdrlen;
	int in_reclen;
	int in_received;
	int in_maxrec;
} RECSTREAM;

static unsigned int fix_buf_size(unsigned int);
static bool_t flush_out(RECSTREAM *, bool_t);
static bool_t fill_input_buf(RECSTREAM *);
static bool_t get_input_bytes(RECSTREAM *, caddr_t, int);
static bool_t set_input_fragment(RECSTREAM *);
static bool_t skip_input_bytes(RECSTREAM *, long);
static bool_t realloc_stream(RECSTREAM *, int);

/*
 * Create an xdr handle for xdrrec
 * xdrrec_create fills in xdrs. Sendsize and recvsize are
 * send and recv buffer sizes (0 => use default).
 * tcp_handle is an opaque handle that is passed as the first parameter to
 * the procedures readit and writeit. Readit and writeit are read and
 * write respectively. They are like the system
 * calls expect that they take an opaque handle rather than an fd.
 */
void __xdrrec_create(XDR *xdrs, unsigned int sendsize, unsigned int recvsize,
	caddr_t tcp_handle,
	int (*readit)(caddr_t, caddr_t, int),	/* like read, but pass it a
						   tcp_handle, not sock */
	int (*writeit)(caddr_t, caddr_t, int))	/* like write, but pass it a
						   tcp_handle, not sock */
{
	RECSTREAM *rstrm =
		(RECSTREAM *)alloc(sizeof(RECSTREAM));

	if (rstrm == NULL) {
		/*
		 *  This is bad.  Should rework xdrrec_create to
		 *  return a handle, and in this case return NULL
		 */
		return;
	}

	rstrm->sendsize = sendsize = fix_buf_size(sendsize);
	rstrm->out_base = malloc(rstrm->sendsize);
	if (rstrm->out_base == NULL) {
		free(rstrm);
		return;
	}

	rstrm->recvsize = recvsize = fix_buf_size(recvsize);
	rstrm->in_base = malloc(recvsize);
	if (rstrm->in_base == NULL) {
		free(rstrm->out_base);
		free(rstrm);
		return;
	}
	/*
	 * now the rest ...
	 */
	xdrs->x_ops = &xdrrec_ops;
	xdrs->x_private = (caddr_t)rstrm;
	rstrm->tcp_handle = tcp_handle;
	rstrm->readit = readit;
	rstrm->writeit = writeit;
	rstrm->out_finger = rstrm->out_boundry = rstrm->out_base;
	rstrm->frag_header = (uint32_t *)rstrm->out_base;
	rstrm->out_finger += sizeof(uint32_t);
	rstrm->out_boundry += sendsize;
	rstrm->frag_sent = FALSE;
	rstrm->in_size = recvsize;
	rstrm->in_boundry = rstrm->in_base;
	rstrm->in_finger = (rstrm->in_boundry += recvsize);
	rstrm->fbtbc = 0;
	rstrm->last_frag = TRUE;
	rstrm->in_haveheader = FALSE;
	rstrm->in_hdrlen = 0;
	rstrm->in_hdrp = (char *)(void *)&rstrm->in_header;
	rstrm->nonblock = FALSE;
	rstrm->in_reclen = 0;
	rstrm->in_received = 0;
}
weak_alias(__xdrrec_create, xdrrec_create);


/*
 * The reoutines defined below are the xdr ops which will go into the
 * xdr handle filled in by xdrrec_create.
 */

static bool_t xdrrec_getlong(XDR *xdrs, long int *lp)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	int32_t *buflp = (int32_t *)(rstrm->in_finger);
	int32_t mylong;

	/* first try the inline, fast case */
	if ((rstrm->fbtbc >= sizeof(int32_t)) &&
		(((long)rstrm->in_boundry - (long)buflp) >= sizeof(int32_t))) {
		*lp = (long)ntohl((uint32_t)(*buflp));
		rstrm->fbtbc -= sizeof(int32_t);
		rstrm->in_finger += sizeof(int32_t);
	} else {
		if (!xdrrec_getbytes(xdrs, (caddr_t)(void *)&mylong,
		    sizeof(int32_t)))
			return FALSE;
		*lp = (long)ntohl((uint32_t)mylong);
	}
	return TRUE;
}

static bool_t xdrrec_putlong(XDR *xdrs, long int *lp)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	int32_t *dest_lp = ((int32_t *)(rstrm->out_finger));

	if ((rstrm->out_finger += sizeof(int32_t)) > rstrm->out_boundry) {
		/*
		 * this case should almost never happen so the code is
		 * inefficient
		 */
		rstrm->out_finger -= sizeof(int32_t);
		rstrm->frag_sent = TRUE;
		if (!flush_out(rstrm, FALSE))
			return FALSE;
		dest_lp = ((int32_t *)(void *)(rstrm->out_finger));
		rstrm->out_finger += sizeof(int32_t);
	}
	*dest_lp = (int32_t)htonl((uint32_t)(*lp));
	return TRUE;
}

/* must manage buffers, fragments, and records */
static bool_t xdrrec_getbytes(XDR *xdrs, caddr_t addr, unsigned int len)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	int current;

	while (len > 0) {
		current = rstrm->fbtbc;
		if (current == 0) {
			if (rstrm->last_frag)
				return FALSE;
			if (!set_input_fragment(rstrm))
				return FALSE;
			continue;
		}
		current = (len < current) ? len : current;
		if (!get_input_bytes(rstrm, addr, current))
			return FALSE;
		addr += current;
		rstrm->fbtbc -= current;
		len -= current;
	}
	return TRUE;
}

static bool_t xdrrec_putbytes(XDR *xdrs, caddr_t addr, unsigned int len)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	long current;

	while (len > 0) {
		current = (unsigned long)rstrm->out_boundry -
		    (unsigned long)rstrm->out_finger;
		current = (len < current) ? len : current;
		memcpy(rstrm->out_finger, addr, current);
		rstrm->out_finger += current;
		addr += current;
		len -= current;
		if (rstrm->out_finger == rstrm->out_boundry) {
			rstrm->frag_sent = TRUE;
			if (!flush_out(rstrm, FALSE))
				return FALSE;
		}
	}
	return TRUE;
}

static unsigned int xdrrec_getpos(XDR *xdrs)
{
	RECSTREAM *rstrm = (RECSTREAM *)xdrs->x_private;
	off_t pos;

	pos = lseek((int)(long)rstrm->tcp_handle, 0, SEEK_CUR);
	if (pos != -1)
		switch (xdrs->x_op) {

		case XDR_ENCODE:
			pos += rstrm->out_finger - rstrm->out_base;
			break;

		case XDR_DECODE:
			pos -= rstrm->in_boundry - rstrm->in_finger;
			break;

		default:
			pos = -1;
			break;
		}
	return (unsigned int)pos;
}

static bool_t xdrrec_setpos(XDR *xdrs, unsigned int pos)
{
	RECSTREAM *rstrm = (RECSTREAM *)xdrs->x_private;
	unsigned int currpos = xdrrec_getpos(xdrs);
	int delta = currpos - pos;
	caddr_t newpos;

	if ((int)currpos != -1)
		switch (xdrs->x_op) {

		case XDR_ENCODE:
			newpos = rstrm->out_finger - delta;
			if ((newpos > (caddr_t)(rstrm->frag_header)) &&
				(newpos < rstrm->out_boundry)) {
				rstrm->out_finger = newpos;
				return TRUE;
			}
			break;

		case XDR_DECODE:
			newpos = rstrm->in_finger - delta;
			if ((delta < (int)(rstrm->fbtbc)) &&
				(newpos <= rstrm->in_boundry) &&
				(newpos >= rstrm->in_base)) {
				rstrm->in_finger = newpos;
				rstrm->fbtbc -= delta;
				return TRUE;
			}
			break;

		case XDR_FREE:
			break;
		}
	return FALSE;
}

static int32_t *xdrrec_inline(XDR *xdrs, unsigned int len)
{
	RECSTREAM *rstrm = (RECSTREAM *)xdrs->x_private;
	int32_t *buf = NULL;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		if ((rstrm->out_finger + len) <= rstrm->out_boundry) {
			buf = (int32_t *) rstrm->out_finger;
			rstrm->out_finger += len;
		}
		break;

	case XDR_DECODE:
		if ((len <= rstrm->fbtbc) &&
			((rstrm->in_finger + len) <= rstrm->in_boundry)) {
			buf = (int32_t *) rstrm->in_finger;
			rstrm->fbtbc -= len;
			rstrm->in_finger += len;
		}
		break;

	case XDR_FREE:
		break;
	}
	return buf;
}

static void xdrrec_destroy(XDR *xdrs)
{
	RECSTREAM *rstrm = (RECSTREAM *)xdrs->x_private;

	free(rstrm->out_base);
	free(rstrm->in_base);
	free(rstrm);
}

/*
 * Exported routines to manage xdr records
 */

/*
 * Before reading (deserializing from the stream, one should always call
 * this procedure to guarantee proper record alignment.
 */
bool_t __xdrrec_skiprecord(XDR *xdrs)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	enum xprt_stat xstat;

	if (rstrm->nonblock) {
		if (__xdrrec_getrec(xdrs, &xstat, FALSE)) {
			rstrm->fbtbc = 0;
			return TRUE;
		}
		if (rstrm->in_finger == rstrm->in_boundry &&
		    xstat == XPRT_MOREREQS) {
			rstrm->fbtbc = 0;
			return TRUE;
		}
		return FALSE;
	}
	while (rstrm->fbtbc > 0 || (!rstrm->last_frag)) {
		if (!skip_input_bytes(rstrm, rstrm->fbtbc))
			return FALSE;
		rstrm->fbtbc = 0;
		if ((!rstrm->last_frag) && (!set_input_fragment(rstrm)))
			return FALSE;
	}
	rstrm->last_frag = FALSE;
	return TRUE;
}
weak_alias(__xdrrec_skiprecord, xdrrec_skiprecord);

/*
 * Look ahead fuction.
 * Returns TRUE iff there is no more input in the buffer
 * after consuming the rest of the current record.
 */
bool_t __xdrrec_eof(XDR *xdrs)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);

	while (rstrm->fbtbc > 0 || (!rstrm->last_frag)) {
		if (!skip_input_bytes(rstrm, rstrm->fbtbc))
			return TRUE;
		rstrm->fbtbc = 0;
		if ((!rstrm->last_frag) && (!set_input_fragment(rstrm)))
			return TRUE;
	}
	if (rstrm->in_finger == rstrm->in_boundry)
		return TRUE;
	return FALSE;
}
weak_alias(__xdrrec_eof, xdrrec_eof);

/*
 * The client must tell the package when an end-of-record has occurred.
 * The second paraemters tells whether the record should be flushed to the
 * (output) tcp stream.  (This let's the package support batched or
 * pipelined procedure calls.)  TRUE => immmediate flush to tcp connection.
 */
bool_t __xdrrec_endofrecord(XDR *xdrs, int32_t sendnow)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	unsigned long len; /* fragment length */

	if (sendnow || rstrm->frag_sent ||
		((unsigned long)rstrm->out_finger + sizeof(uint32_t) >=
		(unsigned long)rstrm->out_boundry)) {
		rstrm->frag_sent = FALSE;
		return flush_out(rstrm, TRUE);
	}
	len = (unsigned long)(rstrm->out_finger) - (unsigned long)(rstrm->frag_header) -
	   sizeof(uint32_t);
	*(rstrm->frag_header) = htonl((unsigned long)len | LAST_FRAG);
	rstrm->frag_header = (uint32_t *)rstrm->out_finger;
	rstrm->out_finger += sizeof(uint32_t);
	return TRUE;
}
weak_alias(__xdrrec_endofrecord, xdrrec_endofrecord);

/*
 * Fill the stream buffer with a record for a non-blocking connection.
 * Return true if a record is available in the buffer, false if not.
 */
bool_t ____xdrrec_getrec(XDR *xdrs, enum xprt_stat *statp, bool_t expectdata)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);
	ssize_t n;
	int fraglen;

	if (!rstrm->in_haveheader) {
		n = rstrm->readit(rstrm->tcp_handle, rstrm->in_hdrp,
		    (int)sizeof(rstrm->in_header) - rstrm->in_hdrlen);
		if (n == 0) {
			*statp = expectdata ? XPRT_DIED : XPRT_IDLE;
			return FALSE;
		}
		if (n < 0) {
			*statp = XPRT_DIED;
			return FALSE;
		}
		rstrm->in_hdrp += n;
		rstrm->in_hdrlen += n;
		if (rstrm->in_hdrlen < sizeof (rstrm->in_header)) {
			*statp = XPRT_MOREREQS;
			return FALSE;
		}
		rstrm->in_header = ntohl(rstrm->in_header);
		fraglen = (int)(rstrm->in_header & ~LAST_FRAG);
		if (fraglen == 0 || fraglen > rstrm->in_maxrec ||
		    (rstrm->in_reclen + fraglen) > rstrm->in_maxrec) {
			*statp = XPRT_DIED;
			return FALSE;
		}
		rstrm->in_reclen += fraglen;
		if (rstrm->in_reclen > rstrm->recvsize)
			realloc_stream(rstrm, rstrm->in_reclen);
		if (rstrm->in_header & LAST_FRAG) {
			rstrm->in_header &= ~LAST_FRAG;
			rstrm->last_frag = TRUE;
		}
	}

	n =  rstrm->readit(rstrm->tcp_handle,
	    rstrm->in_base + rstrm->in_received,
	    (rstrm->in_reclen - rstrm->in_received));

	if (n < 0) {
		*statp = XPRT_DIED;
		return FALSE;
	}

	if (n == 0) {
		*statp = expectdata ? XPRT_DIED : XPRT_IDLE;
		return FALSE;
	}

	rstrm->in_received += n;

	if (rstrm->in_received == rstrm->in_reclen) {
		rstrm->in_haveheader = (FALSE);
		rstrm->in_hdrp = (char *)(void *)&rstrm->in_header;
		rstrm->in_hdrlen = 0;
		if (rstrm->last_frag) {
			rstrm->fbtbc = rstrm->in_reclen;
			rstrm->in_boundry = rstrm->in_base + rstrm->in_reclen;
			rstrm->in_finger = rstrm->in_base;
			rstrm->in_reclen = rstrm->in_received = 0;
			*statp = XPRT_MOREREQS;
			return TRUE;
		}
	}

	*statp = XPRT_MOREREQS;
	return FALSE;
}
strong_alias(____xdrrec_getrec, __xdrrec_getrec);

bool_t __xdrrec_setnonblock(XDR *xdrs, int maxrec)
{
	RECSTREAM *rstrm = (RECSTREAM *)(xdrs->x_private);

	rstrm->nonblock = TRUE;
	if (maxrec == 0)
		maxrec = rstrm->recvsize;
	rstrm->in_maxrec = maxrec;
	return TRUE;
}

/*
 * Internal useful routines
 */
static bool_t flush_out(RECSTREAM *rstrm, int32_t eor)
{
	unsigned long eormask = (eor == TRUE) ? LAST_FRAG : 0;
	uint32_t len = (unsigned long)(rstrm->out_finger) -
		(unsigned long)(rstrm->frag_header) - sizeof(uint32_t);

	*(rstrm->frag_header) = htonl(len | eormask);
	len = (unsigned long)(rstrm->out_finger) - (unsigned long)(rstrm->out_base);
	if ((*(rstrm->writeit))(rstrm->tcp_handle, rstrm->out_base, (int)len)
		!= (int)len)
		return FALSE;
	rstrm->frag_header = (uint32_t *)rstrm->out_base;
	rstrm->out_finger = (caddr_t)rstrm->out_base + sizeof(uint32_t);
	return TRUE;
}

/* knows nothing about records!  Only about input buffers */
static bool_t fill_input_buf(RECSTREAM *rstrm)
{
	caddr_t where;
	unsigned long i;
	long len;

	if (rstrm->nonblock)
		return FALSE;
	where = rstrm->in_base;
	i = (unsigned long)rstrm->in_boundry % BYTES_PER_XDR_UNIT;
	where += i;
	len = rstrm->in_size - i;
	if ((len = (*(rstrm->readit))(rstrm->tcp_handle, where, len)) == -1)
		return FALSE;
	rstrm->in_finger = where;
	where += len;
	rstrm->in_boundry = where;
	return TRUE;
}

/* knows nothing about records!  Only about input buffers */
static bool_t get_input_bytes(RECSTREAM *rstrm, caddr_t addr, int len)
{
	long current;

	if (rstrm->nonblock) {
		if (len > (int)(rstrm->in_boundry - rstrm->in_finger))
			return FALSE;
		memcpy(addr, rstrm->in_finger, len);
		rstrm->in_finger += len;
		return TRUE;
	}

	while (len > 0) {
		current = (long)rstrm->in_boundry - (long)rstrm->in_finger;
		if (current == 0) {
			if (!fill_input_buf(rstrm))
				return FALSE;
			continue;
		}
		current = (len < current) ? len : current;
		memcpy(addr, rstrm->in_finger, current);
		rstrm->in_finger += current;
		addr += current;
		len -= current;
	}
	return TRUE;
}

/* next four bytes of the input stream are treated as a header */
static bool_t set_input_fragment(RECSTREAM *rstrm)
{
	uint32_t header;

	if (rstrm->nonblock)
		return FALSE;
	if (!get_input_bytes(rstrm, (caddr_t)&header, sizeof(header)))
		return FALSE;
	header = (long)ntohl(header);
	rstrm->last_frag = ((header & LAST_FRAG) == 0) ? FALSE : TRUE;
	/*
	 * Sanity check. Try not to accept wildly incorrect
	 * record sizes. Unfortunately, the only record size
	 * we can positively identify as being 'wildly incorrect'
	 * is zero. Ridiculously large record sizes may look wrong,
	 * but we don't have any way to be certain that they aren't
	 * what the client actually intended to send us.
	 */
	if (header == 0)
		return FALSE;
	rstrm->fbtbc = header & (~LAST_FRAG);
	return TRUE;
}

/* consumes input bytes; knows nothing about records! */
static bool_t skip_input_bytes(RECSTREAM *rstrm, long int cnt)
{
	long current;

	while (cnt > 0) {
		current = (long)rstrm->in_boundry - (long)rstrm->in_finger;
		if (current == 0) {
			if (!fill_input_buf(rstrm))
				return FALSE;
			continue;
		}
		current = (cnt < current) ? cnt : current;
		rstrm->in_finger += current;
		cnt -= current;
	}
	return TRUE;
}

static unsigned int fix_buf_size(unsigned int s)
{

	if (s < 100)
		s = 4000;
	return RNDUP(s);
}

/*
 * Reallocate the input buffer for a non-block stream.
 */
static bool_t realloc_stream(RECSTREAM *rstrm, int size)
{
	ptrdiff_t diff;
	char *buf;

	if (size > rstrm->recvsize) {
		buf = realloc(rstrm->in_base, size);
		if (buf == NULL)
			return FALSE;
		diff = buf - rstrm->in_base;
		rstrm->in_finger += diff;
		rstrm->in_base = buf;
		rstrm->in_boundry = buf + size;
		rstrm->recvsize = size;
		rstrm->in_size = size;
	}

	return TRUE;
}
