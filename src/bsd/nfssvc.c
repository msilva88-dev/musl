#define _BSD_SOURCE
#include <sys/statfs.h>
#include <sys/types.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/ucred.h>
#include <hyperbk/nfs/nfsproto.h>
#include <hyperbk/nfs/nfs.h>
#elif defined(__OpenBSD__)
#include <sys/ucred.h>
#include <nfs/nfsproto.h>
#include <nfs/nfs.h>
#endif
#include <unistd.h>
#include "syscall.h"

int nfssvc(int flags, void *argp)
{
        return syscall(SYS_nfssvc, flags, argp);
}
