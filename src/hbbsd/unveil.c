#define _BSD_SOURCE
#include <sys/namei.h>
#include "syscall.h"

int unveil(const char *path, const char *permissions)
{
    return syscall(SYS_unveil, path, permissions);
}
