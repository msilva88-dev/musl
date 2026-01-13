#define _BSD_SOURCE
#include <sys/types.h>
#include <stdlib.h>

qdiv_t qdiv(quad_t num, quad_t den)
{
	lldiv_t tmp = lldiv((quad_t)num, (quad_t)den);
	qdiv_t result;
	result.quot = tmp.quot;
	result.rem = tmp.rem;
	return result;
}
