#define _BSD_SOURCE
#include <unistd.h>
#include "syscall.h"

int profil(char *samples, size_t size, unsigned long off, unsigned int scale)
{
        return syscall(SYS_profil, samples, size, off, scale);
}
