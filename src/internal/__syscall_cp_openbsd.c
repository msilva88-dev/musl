/* OpenBSD stage-1:
 * Provide a non-threaded __syscall_cp so libc objects that expect the
 * cancellable wrapper (e.g. write) can link without pulling in pthreads.
 * We just forward to the raw syscall path.
 */
#ifdef MUSL_OBSD
#include "syscall.h"

/* The name __syscall_cp is a macro in syscall.h; we are defining the
 * actual symbol here, so drop the macro first.
 */
#undef __syscall_cp

__attribute__((visibility("hidden")))
long __syscall_cp(long n,
                  long a1, long a2, long a3,
                  long a4, long a5, long a6)
{
	/* No cancellation in stage-1: just do the syscall. */
	return __syscall(n, a1, a2, a3, a4, a5, a6);
}
#endif
