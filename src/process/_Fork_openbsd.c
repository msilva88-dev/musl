/* OpenBSD Stage-1: minimal _Fork().
 * Single-threaded bootstrap; just invoke fork(2).
 */
#include <sys/types.h>
#include <sys/syscall.h>
#include "syscall.h"

pid_t _Fork(void)
{
	long r = __syscall(SYS_fork);
	return __syscall_ret(r);
}
