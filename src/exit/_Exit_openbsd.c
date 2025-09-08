#include "syscall.h"

/* OpenBSD stage-1: no exit_group; use plain exit. */
_Noreturn void _Exit(int ec)
{
	__syscall(SYS_exit, ec);
	for (;;)
		__syscall(SYS_exit, ec);
}
