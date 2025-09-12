#ifndef _MUSL_OBSD_BITS_SYSCALL_H
#define _MUSL_OBSD_BITS_SYSCALL_H
/* Map/define Linux-only names here later if needed. */

/* --- Compatibility aliases for musl sources expecting Linux names --- */
/* brk(2) is named obreak(2) on OpenBSD */
#if defined(SYS_obreak) && !defined(SYS_brk)
#define SYS_brk SYS_obreak
#endif

/* add more aliases here as they show up during bring-up */
/* e.g.
#if defined(SYS___getcwd) && !defined(SYS_getcwd)
#define SYS_getcwd SYS___getcwd
#endif */

/* ---- BSD syscall name compatibility shims -------------------------
 * OpenBSD exposes System V IPC control syscalls with leading
 * double-underscore names; musl’s generic code expects SYS_* without
 * underscores.  Provide aliases when appropriate.
 */
#if !defined(SYS_semctl) && defined(SYS___semctl)
#define SYS_semctl SYS___semctl
#endif
#if !defined(SYS_msgctl) && defined(SYS___msgctl)
#define SYS_msgctl SYS___msgctl
#endif
#if !defined(SYS_shmctl) && defined(SYS___shmctl)
#define SYS_shmctl SYS___shmctl
#endif

#endif
