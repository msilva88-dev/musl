/* OpenBSD setrlimit wrapper for Stage-1
 *
 * Use the native setrlimit(2) syscall rather than Linux prlimit64.
 */
#include <sys/resource.h>
#include "syscall.h"

int setrlimit(int resource, const struct rlimit *rlim)
{
	long r = __syscall(SYS_setrlimit, resource, rlim);
	return __syscall_ret(r);
}
