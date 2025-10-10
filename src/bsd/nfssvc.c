#define _BSD_SOURCE
#if defined(__HyperbolaBSD__)
#include <hyperbk/nfs/nfs.h>
#elif defined(__OpenBSD__)
#include <nfs/nfs.h>
#endif
#include <unistd.h>
#include "syscall.h"

int nfssvc(int flags, void *argp);
{
        return syscall(SYS_nfssvc, argp);
}
