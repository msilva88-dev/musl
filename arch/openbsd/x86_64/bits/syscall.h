#ifndef _MUSL_OBSD_BITS_SYSCALL_H
#define _MUSL_OBSD_BITS_SYSCALL_H
/* OpenBSD syscall numbers for amd64.
 * musl builds with -nostdinc, so we include the system header via an
 * absolute path to make the numbers visible without modifying flags.
 * If your system uses a different root, adjust the path below.
 */
#include "/usr/include/sys/syscall.h"

/* If musl code references Linux-only names, add shims here later, e.g.:
 * #define SYS_getrandom  /* not present on OpenBSD */
 * // but we implement getrandom via SYS_getentropy in our openbsd file.
 */

#endif
