/* OpenBSD Stage-1: fchmodat via native syscall (no fchmodat2). */
#include <sys/types.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <sys/stat.h>
#include "syscall.h"

int fchmodat(int fd, const char *path, mode_t mode, int flag)
{
    /* OpenBSD provides fchmodat(2) with (fd, path, mode, flag). */
#ifdef SYS_fchmodat
    long r = __syscall(SYS_fchmodat, fd, path, mode, flag);
    return __syscall_ret(r);
#else
    /* Should not happen on OpenBSD 7.0, but keep a graceful fallback. */
    (void)fd; (void)path; (void)mode; (void)flag;
    errno = ENOSYS;
    return -1;
#endif
}
