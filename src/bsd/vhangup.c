#define _GNU_SOURCE
#include <unistd.h>
#include "syscall.h"

// vhangup_wrapper

int vhangup(void)
{
	int fd = STDIN_FILENO;
	struct termios t;

	if (tcgetattr(fd, &t) == 0) {
		t.c_lflag &= ~(ECHO | ICANON);
		tcsetattr(fd, TCSAFLUSH, &t);
	}

	if (ioctl(fd, TIOCNOTTY, 0) < 0) {
		errno = ENOSYS;
		return -1;
	}

	close(fd);

	return 0;
}
