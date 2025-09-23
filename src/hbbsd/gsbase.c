#include <sys/sysarch.h>

#if defined(__i386__)
#define ARCH_GET_GSBASE I386_GET_GSBASE
#define ARCH_SET_GSBASE I386_SET_GSBASE
#endif

int get_fsbase(void **base)
{
	return sysarch(ARCH_GET_GSBASE, base);
}

int set_fsbase(void *base)
{
	return sysarch(ARCH_SET_GSBASE, base);
}
