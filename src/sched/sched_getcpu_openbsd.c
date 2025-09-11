/* OpenBSD Stage-1: no getcpu(2).
 *
 * Provide a minimal stub and avoid including any of musl's generic
 * sched_getcpu.c or internal syscall headers (which pull in
 * Linux-only SYS_getcpu names).  This file must be self-contained.
 */
#include <errno.h>   /* errno, ENOSYS */

int sched_getcpu(void)
{
	errno = ENOSYS;
	return -1;
}
