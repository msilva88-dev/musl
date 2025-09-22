#include <sys/sysarch.h>

#if defined(__i386__)
#define ARCH_IOPL I386_IOPL
#define ARCH_IOPL_ARGS i386_iopl_args
#elif defined(__x86_64__)
#define ARCH_IOPL AMD64_IOPL
#define ARCH_IOPL_ARGS amd64_iopl_args
#endif

int iopl(int level)
{
	struct ARCH_IOPL_ARGS args;
	args.iopl = level;
	return sysarch(ARCH_IOPL, &args);
}
