#define _BSD_SOURCE
#include <sys/types.h>
#include <stdlib.h>

quad_t qabs(quad_t a)
{
	return (quad_t)llabs((quad_t)a);
}
