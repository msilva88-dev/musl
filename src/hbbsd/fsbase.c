#include <sys/sysarch.h>

#if defined(__i386__)
#define ARCH_GET_FSBASE I386_GET_FSBASE
#define ARCH_SET_FSBASE I386_SET_FSBASE
#endif

int get_fsbase(void **base)
{
	return sysarch(ARCH_GET_FSBASE, base);
}

int set_fsbase(void *base)
{
	return sysarch(ARCH_SET_FSBASE, base);
}
