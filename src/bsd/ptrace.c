#define _BSD_SOURCE

#define __NEED_pid_t
#define __NEED_size_t

#include <bits/alltypes.h>

#include <sys/types.h>
#include <sys/ptrace.h>
#include "syscall.h"

int ptrace(int req, pid_t pid, caddr_t addr, int data)
{
	return syscall(SYS_ptrace, req, pid, addr, data);
}
