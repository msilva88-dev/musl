/* OpenBSD stage-1 posix_fallocate(): portable fallback.
 * Ensure the file is at least base+len bytes using fstat/ftruncate.
 * We do not attempt to force physical allocation; this is sufficient
 * for bootstrap and is acceptable per POSIX as a best-effort.
 */
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

int posix_fallocate(int fd, off_t base, off_t len)
{
	if (base < 0 || len < 0) return EINVAL;
	if (len == 0) return 0;

	off_t end;
	/* Check overflow: end = base + len must not wrap. */
	if (__builtin_add_overflow(base, len, &end)) return EINVAL;

	struct stat st;
	if (fstat(fd, &st) < 0) return errno;

	if (end <= st.st_size) return 0;

	/* Extend to end. This preserves file offset and mode. */
	if (ftruncate(fd, end) < 0) return errno;

	return 0;
}
