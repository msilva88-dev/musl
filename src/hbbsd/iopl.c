#if defined(__i386__) || defined(__x86_64__)
#include <sys/sysarch.h>

int iopl(int level)
{
#ifdef __i386__
	struct i386_iopl_args args;
	args.iopl = level;
	return sysarch(I386_IOPL, &args);
#else
	struct amd64_iopl_args args;
	args.iopl = level;
	return sysarch(AMD64_IOPL, &args);
#endif
}
#endif
