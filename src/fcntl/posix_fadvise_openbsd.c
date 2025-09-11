/* OpenBSD stage-1:
 * There is no SYS_fadvise; treat the hint as a no-op and succeed.
 * This is acceptable for bootstrap; callers usually ignore errors.
 */
#include <fcntl.h>
#include <sys/types.h>

int posix_fadvise(int fd, off_t base, off_t len, int advice)
{
	(void)fd;
	(void)base;
	(void)len;
	(void)advice;
	return 0;
}
