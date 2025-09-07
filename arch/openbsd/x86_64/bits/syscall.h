#ifndef _MUSL_OBSD_BITS_SYSCALL_H
#define _MUSL_OBSD_BITS_SYSCALL_H
/* OpenBSD syscall numbers for amd64.
 * Use an absolute path so we don't have to expose /usr/include globally.
 */
#include "/usr/include/sys/syscall.h"

/* Map/define Linux-only names here later if needed. */

/* --- Compatibility aliases for musl sources expecting Linux names --- */
/* brk(2) is named obreak(2) on OpenBSD */
#if defined(SYS_obreak) && !defined(SYS_brk)
#define SYS_brk SYS_obreak
#endif

/* add more aliases here as they pop up during bring-up */
/* e.g. #if defined(SYS___getcwd) && !defined(SYS_getcwd)
 * #define SYS_getcwd SYS___getcwd
 * #endif */

#endif
