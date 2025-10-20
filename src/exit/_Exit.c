#include <stdlib.h>
#include "syscall.h"

_Noreturn void _Exit(int ec)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	__syscall(SYS_exit, ec);
#elif defined(__linux__)
	__syscall(SYS_exit_group, ec);
	for (;;) __syscall(SYS_exit, ec);
#endif
}
