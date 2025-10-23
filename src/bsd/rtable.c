#define _BSD_SOURCE
#include <sys/socket.h>
#include "syscall.h"

int getrtable(void);
{
	return syscall(SYS_getrtable);
}

int setrtable(int id)
{
	return syscall(SYS_setrtable, id);
}
