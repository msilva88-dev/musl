#include <sys/sysarch.h>

#if defined(__i386__)
#define ARCH_IOPL I386_IOPL
#define ARCH_IOPL_ARGS i386_iopl_args
#elif defined(__x86_64__)
#define ARCH_IOPL AMD64_IOPL
#define ARCH_IOPL_ARGS amd64_iopl_args
#endif

#if defined(__OpenBSD__)
static
#endif
int iopl(int level)
{
	struct ARCH_IOPL_ARGS args;
	args.iopl = level;
	return sysarch(ARCH_IOPL, &args);
}

#if defined(__i386__)
int i386_iopl(int level)
{
	return iopl(level);
}
#elif defined(__x86_64__)
int amd64_iopl(int level)
{
	return iopl(level);
}
#endif
