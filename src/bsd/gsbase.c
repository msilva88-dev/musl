#include <sys/sysarch.h>

#if defined(__i386__)

#define ARCH_GET_GSBASE I386_GET_GSBASE
#define ARCH_SET_GSBASE I386_SET_GSBASE

#if defined(__OpenBSD__)
static
#endif
int get_gsbase(void **base)
{
	return sysarch(ARCH_GET_GSBASE, base);
}

#if defined(__OpenBSD__)
static
#endif
int set_gsbase(void *base)
{
	return sysarch(ARCH_SET_GSBASE, base);
}

int i386_get_gsbase(void **base)
{
	return get_gsbase(base);
}

int i386_set_gsbase(void *base)
{
	return set_gsbase(base);
}

#endif
