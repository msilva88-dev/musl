#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int kbind(const struct __kbind *param, size_t psize, int64_t cookie)
{
        return syscall(SYS_kbind, param, psize, cookie);
}
