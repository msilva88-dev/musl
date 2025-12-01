#define _BSD_SOURCE
#include <sys/types.h>
#include <stdlib.h>

qdiv_t qdiv(quad_t num, quad_t den)
{
	return (qdiv_t)lldiv((quad_t)num, (quad_t)den);
}
