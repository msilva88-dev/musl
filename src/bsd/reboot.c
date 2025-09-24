#include <sys/reboot.h>
#include "syscall.h"

int reboot(int opt)
{
	return syscall(SYS_reboot, opt);
}
