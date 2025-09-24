#include <sys/ptrace.h>
#include "syscall.h"

int ptrace(int req, pid_t pid, caddr_t addr, int data)
{
	return syscall(SYS_ptrace, req, pid, addr, data);
}
