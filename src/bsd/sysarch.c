#define _BSD_SOURCE
#include <sys/sysarch.h>
#include "syscall.h"

int sysarch(int op, void *parms)
{
        return syscall(SYS_sysarch, op, parms);
}
