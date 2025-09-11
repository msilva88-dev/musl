/* OpenBSD uname() — Stage-1 stub (no sysctl).
 * Good enough for static bootstrap, avoids pulling kernel headers.
 */
#include <sys/utsname.h>
#include <string.h>
#include <errno.h>

int uname(struct utsname *u)
{
	if (!u) { errno = EFAULT; return -1; }
	memset(u, 0, sizeof *u);
	/* Conservative placeholders; adjust later when sysctl wrapper exists. */
	strlcpy(u->sysname,  "OpenBSD",     sizeof u->sysname);
	strlcpy(u->nodename, "localhost",   sizeof u->nodename);
	strlcpy(u->release,  "0",           sizeof u->release);
	strlcpy(u->version,  "musl-stage1", sizeof u->version);
#if defined(__x86_64__) || defined(__amd64__)
	strlcpy(u->machine,  "amd64",       sizeof u->machine);
#else
	strlcpy(u->machine,  "unknown",     sizeof u->machine);
#endif
	return 0;
}
