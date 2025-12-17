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

/* xdr from OpenBSD 7.0 source code: lib/libc/rpc/xdr.c */

/*
 * xdr.c, Generic XDR routines implementation.
 *
 * These are the "generic" xdr routines used to serialize and de-serialize
 * most common data items.  See xdr.h for more info on the interface to
 * xdr.
 */

#define _BSD_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <rpc/types.h>
#include <rpc/xdr.h>

/*
 * constants specific to the xdr "protocol"
 */
#define XDR_FALSE	((long) 0)
#define XDR_TRUE	((long) 1)
#define LASTUNSIGNED	((unsigned int) 0-1)

/*
 * for unit alignment
 */
static char xdr_zero[BYTES_PER_XDR_UNIT] = { 0, 0, 0, 0 };

/*
 * Free a data structure using XDR
 * Not a filter, but a convenient utility nonetheless
 */
void __xdr_free(xdrproc_t proc, char *objp)
{
	XDR x;

	x.x_op = XDR_FREE;
	(*proc)(&x, objp);
}
weak_alias(__xdr_free, xdr_free);

/*
 * XDR nothing
 */
bool_t __xdr_void(void) /* (XDR *xdrs, caddr_t addr) */
{
	return TRUE;
}
weak_alias(__xdr_void, xdr_void);


/*
 * XDR integers
 */
bool_t __xdr_int(XDR *xdrs, int *ip)
{
	long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (long) *ip;
		return XDR_PUTLONG(xdrs, &l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, &l)) {
			return FALSE;
		}
		*ip = (int) l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_int, xdr_int);

/*
 * XDR unsigned integers
 */
bool_t __xdr_u_int(XDR *xdrs, unsigned int *up)
{
	unsigned long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (unsigned long) *up;
		return XDR_PUTLONG(xdrs, (long *)&l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, (long *)&l)) {
			return FALSE;
		}
		*up = (unsigned int) l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_u_int, xdr_u_int);


/*
 * XDR long integers
 * same as xdr_u_long - open coded to save a proc call!
 */
bool_t __xdr_long(XDR *xdrs, long int *lp)
{
	switch (xdrs->x_op) {
	case XDR_ENCODE:
		return XDR_PUTLONG(xdrs, lp);
	case XDR_DECODE:
		return XDR_GETLONG(xdrs, lp);
	case XDR_FREE:
		return TRUE;
	}

	return FALSE;
}
weak_alias(__xdr_long, xdr_long);

/*
 * XDR unsigned long integers
 * same as xdr_long - open coded to save a proc call!
 */
bool_t __xdr_u_long(XDR *xdrs, unsigned long *ulp)
{
	switch (xdrs->x_op) {
	case XDR_ENCODE:
		return XDR_PUTLONG(xdrs, (long *)ulp);
	case XDR_DECODE:
		return XDR_GETLONG(xdrs, (long *)ulp);
	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_u_long, xdr_u_long);

/*
 * XDR 32-bit integers
 * same as xdr_u_int32_t - open coded to save a proc call!
 */
bool_t xdr_int32_t(XDR *xdrs, int32_t *int32_p)
{
	long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (long) *int32_p;
		return XDR_PUTLONG(xdrs, &l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, &l)) {
			return FALSE;
		}
		*int32_p = (int32_t)l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}

/*
 * XDR unsigned 32-bit integers
 * same as xdr_int32_t - open coded to save a proc call!
 */
bool_t __xdr_u_int32_t(XDR *xdrs, u_int32_t *uint32_p)
{
	unsigned long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (unsigned long) *uint32_p;
		return XDR_PUTLONG(xdrs, (long *)&l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, (long *)&l)) {
			return FALSE;
		}
		*uint32_p = (u_int32_t)l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_u_int32_t, xdr_u_int32_t);

/*
 * XDR short integers
 */
bool_t __xdr_short(XDR *xdrs, short int *sp)
{
	long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (long)*sp;
		return XDR_PUTLONG(xdrs, &l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, &l)) {
			return FALSE;
		}
		*sp = (short)l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_short, xdr_short);

/*
 * XDR unsigned short integers
 */
bool_t __xdr_u_short(XDR *xdrs, unsigned short *usp)
{
	unsigned long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (unsigned long) *usp;
		return XDR_PUTLONG(xdrs, (long *)&l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, (long *)&l)) {
			return FALSE;
		}
		*usp = (unsigned short) l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_u_short, xdr_u_short);

/*
 * XDR 16-bit integers
 */
bool_t xdr_int16_t(XDR *xdrs, int16_t *int16_p)
{
	long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (long)*int16_p;
		return XDR_PUTLONG(xdrs, &l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, &l)) {
			return FALSE;
		}
		*int16_p = (int16_t)l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}

/*
 * XDR unsigned 16-bit integers
 */
bool_t xdr_u_int16_t(XDR *xdrs, u_int16_t *uint16_p)
{
	unsigned long l;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		l = (unsigned long)*uint16_p;
		return XDR_PUTLONG(xdrs, (long *)&l);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, (long *)&l)) {
			return FALSE;
		}
		*uint16_p = (u_int16_t)l;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}

/*
 * XDR a char
 */
bool_t xdr_char(XDR *xdrs, char *cp)
{
	int i;

	i = (*cp);
	if (!xdr_int(xdrs, &i)) {
		return FALSE;
	}
	*cp = i;
	return TRUE;
}

/*
 * XDR an unsigned char
 */
bool_t xdr_u_char(XDR *xdrs, unsigned char *cp)
{
	unsigned int u;

	u = (*cp);
	if (!xdr_u_int(xdrs, &u)) {
		return FALSE;
	}
	*cp = u;
	return TRUE;
}

/*
 * XDR booleans
 */
bool_t __xdr_bool(XDR *xdrs, int32_t *bp)
{
	long lb;

	switch (xdrs->x_op) {

	case XDR_ENCODE:
		lb = *bp ? XDR_TRUE : XDR_FALSE;
		return XDR_PUTLONG(xdrs, &lb);

	case XDR_DECODE:
		if (!XDR_GETLONG(xdrs, &lb)) {
			return FALSE;
		}
		*bp = (lb == XDR_FALSE) ? FALSE : TRUE;
		return TRUE;

	case XDR_FREE:
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_bool, xdr_bool);

/*
 * XDR enumerations
 */
bool_t __xdr_enum(XDR *xdrs, enum_t *ep)
{
	enum sizecheck { SIZEVAL }; /* used to find the size of an enum */

	/*
	 * enums are treated as ints
	 */
	if (sizeof(enum sizecheck) == sizeof(long)) {
		return xdr_long(xdrs, (long *)ep);
	} else if (sizeof (enum sizecheck) == sizeof(int)) {
		return xdr_int(xdrs, (int *)ep);
	} else if (sizeof (enum sizecheck) == sizeof(short)) {
		return xdr_short(xdrs, (short *)ep);
	} else {
		return FALSE;
	}
}
weak_alias(__xdr_enum, xdr_enum);

/*
 * XDR opaque data
 * Allows the specification of a fixed size sequence of opaque bytes.
 * cp points to the opaque object and cnt gives the byte length.
 */
bool_t __xdr_opaque(XDR *xdrs, caddr_t cp, unsigned int cnt)
{
	unsigned int rndup;
	static int crud[BYTES_PER_XDR_UNIT];

	/*
	 * if no data we are done
	 */
	if (cnt == 0)
		return TRUE;

	/*
	 * round byte count to full xdr units
	 */
	rndup = cnt % BYTES_PER_XDR_UNIT;
	if (rndup > 0)
		rndup = BYTES_PER_XDR_UNIT - rndup;

	if (xdrs->x_op == XDR_DECODE) {
		if (!XDR_GETBYTES(xdrs, cp, cnt)) {
			return FALSE;
		}
		if (rndup == 0)
			return TRUE;
		return XDR_GETBYTES(xdrs, (caddr_t)crud, rndup);
	}

	if (xdrs->x_op == XDR_ENCODE) {
		if (!XDR_PUTBYTES(xdrs, cp, cnt)) {
			return FALSE;
		}
		if (rndup == 0)
			return TRUE;
		return XDR_PUTBYTES(xdrs, xdr_zero, rndup);
	}

	if (xdrs->x_op == XDR_FREE) {
		return TRUE;
	}

	return FALSE;
}
weak_alias(__xdr_opaque, xdr_opaque);

/*
 * XDR counted bytes
 * *cpp is a pointer to the bytes, *sizep is the count.
 * If *cpp is NULL maxsize bytes are allocated
 */
bool_t __xdr_bytes(XDR *xdrs, char **cpp, unsigned int *sizep,
	unsigned int maxsize)
{
	char *sp = *cpp; /* sp is the actual string pointer */
	unsigned int nodesize;

	/*
	 * first deal with the length since xdr bytes are counted
	 */
	if (!xdr_u_int(xdrs, sizep)) {
		return FALSE;
	}
	nodesize = *sizep;
	if ((nodesize > maxsize) && (xdrs->x_op != XDR_FREE)) {
		return FALSE;
	}

	/*
	 * now deal with the actual bytes
	 */
	switch (xdrs->x_op) {

	case XDR_DECODE:
		if (nodesize == 0) {
			return TRUE;
		}
		if (sp == NULL) {
			*cpp = sp = (char *)alloc(nodesize);
		}
		if (sp == NULL)
			return FALSE;
		/* fall into ... */

	case XDR_ENCODE:
		return xdr_opaque(xdrs, sp, nodesize);

	case XDR_FREE:
		if (sp != NULL) {
			free(sp);
			*cpp = NULL;
		}
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_bytes, xdr_bytes);

/*
 * Implemented here due to commonality of the object.
 */
bool_t xdr_netobj(XDR *xdrs, struct netobj *np)
{
	return xdr_bytes(xdrs, &np->n_bytes, &np->n_len, MAX_NETOBJ_SZ);
}

/*
 * XDR a descriminated union
 * Support routine for discriminated unions.
 * You create an array of xdrdiscrim structures, terminated with
 * an entry with a null procedure pointer.  The routine gets
 * the discriminant value and then searches the array of xdrdiscrims
 * looking for that value.  It calls the procedure given in the xdrdiscrim
 * to handle the discriminant.  If there is no specific routine a default
 * routine may be called.
 * If there is no specific or default routine an error is returned.
 */
bool_t __xdr_union(
	XDR *xdrs,
	enum_t *dscmp,			/* enum to decide which arm to work on */
	char *unp,			/* the union itself */
	struct xdr_discrim *choices,	/* [value, xdr proc] for each arm */
	xdrproc_t dfault)		/* default xdr routine */
{
	int32_t dscm;

	/*
	 * we deal with the discriminator;  it's an enum
	 */
	if (!xdr_enum(xdrs, dscmp)) {
		return FALSE;
	}
	dscm = *dscmp;

	/*
	 * search choices for a value that matches the discriminator.
	 * if we find one, execute the xdr routine for that value.
	 */
	for (; choices->proc != NULL; choices++) {
		if (choices->value == dscm)
			return (*(choices->proc))(xdrs, unp);
	}

	/*
	 * no match - execute the default xdr routine if there is one
	 */
	return (dfault == NULL) ? FALSE : (*dfault)(xdrs, unp);
}
weak_alias(__xdr_union, xdr_union);


/*
 * Non-portable xdr primitives.
 * Care should be taken when moving these routines to new architectures.
 */


/*
 * XDR null terminated ASCII strings
 * xdr_string deals with "C strings" - arrays of bytes that are
 * terminated by a NULL character.  The parameter cpp references a
 * pointer to storage; If the pointer is null, then the necessary
 * storage is allocated.  The last parameter is the max allowed length
 * of the string as specified by a protocol.
 */
bool_t __xdr_string(XDR *xdrs, char **cpp, unsigned int maxsize)
{
	char *sp = *cpp;  /* sp is the actual string pointer */
	unsigned int size;
	unsigned int nodesize;

	/*
	 * first deal with the length since xdr strings are counted-strings
	 */
	switch (xdrs->x_op) {
	case XDR_FREE:
		if (sp == NULL) {
			return TRUE; /* already free */
		}
		/* fall through... */
	case XDR_ENCODE:
		size = strlen(sp);
		break;
	default:
		break;
	}
	if (!xdr_u_int(xdrs, &size)) {
		return FALSE;
	}
	if (size > maxsize) {
		return FALSE;
	}
	nodesize = size + 1;

	/*
	 * now deal with the actual bytes
	 */
	switch (xdrs->x_op) {

	case XDR_DECODE:
		if (nodesize == 0) {
			return TRUE;
		}
		if (sp == NULL)
			*cpp = sp = (char *)alloc(nodesize);
		if (sp == NULL)
			return FALSE;
		sp[size] = 0;
		/* fall into ... */

	case XDR_ENCODE:
		return xdr_opaque(xdrs, sp, size);

	case XDR_FREE:
		free(sp);
		*cpp = NULL;
		return TRUE;
	}
	return FALSE;
}
weak_alias(__xdr_string, xdr_string);

/*
 * Wrapper for xdr_string that can be called directly from
 * routines like clnt_call
 */
bool_t xdr_wrapstring(XDR *xdrs, char **cpp)
{
	return xdr_string(xdrs, cpp, LASTUNSIGNED);
}

bool_t xdr_int64_t(XDR *xdrs, int64_t *llp)
{
	unsigned long ul[2];

	switch (xdrs->x_op) {
	case XDR_ENCODE:
		ul[0] = (unsigned long)((uint64_t)*llp >> 32) & 0xffffffff;
		ul[1] = (unsigned long)((uint64_t)*llp) & 0xffffffff;
		if (XDR_PUTLONG(xdrs, (long *)&ul[0]) == FALSE)
			return FALSE;
		return XDR_PUTLONG(xdrs, (long *)&ul[1]);
	case XDR_DECODE:
		if (XDR_GETLONG(xdrs, (long *)&ul[0]) == FALSE)
			return FALSE;
		if (XDR_GETLONG(xdrs, (long *)&ul[1]) == FALSE)
			return FALSE;
		*llp = (int64_t)
		    (((uint64_t)ul[0] << 32) | ((uint64_t)ul[1]));
		return TRUE;
	case XDR_FREE:
		return TRUE;
	}
	/* NOTREACHED */
	return FALSE;
}

bool_t xdr_u_int64_t(XDR *xdrs, u_int64_t *ullp)
{
	unsigned long ul[2];

	switch (xdrs->x_op) {
	case XDR_ENCODE:
		ul[0] = (unsigned long)(*ullp >> 32) & 0xffffffff;
		ul[1] = (unsigned long)(*ullp) & 0xffffffff;
		if (XDR_PUTLONG(xdrs, (long *)&ul[0]) == FALSE)
			return FALSE;
		return XDR_PUTLONG(xdrs, (long *)&ul[1]);
	case XDR_DECODE:
		if (XDR_GETLONG(xdrs, (long *)&ul[0]) == FALSE)
			return FALSE;
		if (XDR_GETLONG(xdrs, (long *)&ul[1]) == FALSE)
			return FALSE;
		*ullp = (u_int64_t)
		    (((u_int64_t)ul[0] << 32) | ((u_int64_t)ul[1]));
		return TRUE;
	case XDR_FREE:
		return TRUE;
	}
	/* NOTREACHED */
	return FALSE;
}
