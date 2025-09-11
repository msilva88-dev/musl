/* OpenBSD getrlimit wrapper for Stage-1
 *
 * Use the native getrlimit(2) syscall rather than Linux prlimit64.
 */
#include <sys/resource.h>
#include "syscall.h"

int getrlimit(int resource, struct rlimit *rlim)
{
	long r = __syscall(SYS_getrlimit, resource, rlim);
	return __syscall_ret(r);
}
