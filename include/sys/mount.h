#ifndef _SYS_MOUNT_H
#define _SYS_MOUNT_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#include <sys/statfs.h>
#if defined(__OpenBSD__)
#include <sys/mount_info.h>
#endif
#elif defined(__linux__)
#include <sys/ioctl.h>
#endif

#define BLKROSET   _IO(0x12, 93)
#define BLKROGET   _IO(0x12, 94)
#define BLKRRPART  _IO(0x12, 95)
#define BLKGETSIZE _IO(0x12, 96)
#define BLKFLSBUF  _IO(0x12, 97)
#define BLKRASET   _IO(0x12, 98)
#define BLKRAGET   _IO(0x12, 99)
#define BLKFRASET  _IO(0x12,100)
#define BLKFRAGET  _IO(0x12,101)
#define BLKSECTSET _IO(0x12,102)
#define BLKSECTGET _IO(0x12,103)
#define BLKSSZGET  _IO(0x12,104)
#define BLKBSZGET  _IOR(0x12,112,size_t)
#define BLKBSZSET  _IOW(0x12,113,size_t)
#define BLKGETSIZE64 _IOR(0x12,114,size_t)

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define MNT_RDONLY      1
#define MNT_SYNCHRONOUS 2
#define MNT_NOEXEC      4
#define MNT_NOSUID      8
#define MNT_NODEV       16
#define MNT_NOPERM      32 // FFS/FFS2 only
#define MNT_ASYNC       64
#define MNT_EXRDONLY    128 // exported mount
#define MNT_EXPORTED    256 // exported mount
#define MNT_DEFEXPORTED 512 // exported mount
#define MNT_EXPORTANON  1024 // exported mount
#define MNT_WXALLOWED   2048 // FFS/FFS2 only
#define MNT_LOCAL       4096 // internal only
#define MNT_QUOTA       8192 // internal only
#define MNT_ROOTFS      16384 // internal only
#define MNT_NOATIME     32768
#define MNT_UPDATE      (1<<16)
#define MNT_DELEXPORT   (1<<17)
#define MNT_RELOAD      (1<<18)
#define MNT_FORCE       (1<<19) // Mount and unmount flag
#define MNT_STALLED     (1<<20)
#define MNT_SWAPPABLE   (1<<21) // Swap only
#define MNT_WANTRDWR    (1<<25)
#define MNT_SOFTDEP     (1<<26) // FFS/FFS2 only
#define MNT_DOOMED      (1<<27)
#if defined(__HyperbolaBSD__)
#define MS_RDONLY      MNT_RDONLY
#define MS_NOSUID      MNT_NOSUID
#define MS_NODEV       MNT_NODEV
#define MS_NOEXEC      MNT_NOEXEC
#define MS_SYNCHRONOUS MNT_SYNCHRONOUS
#define MS_REMOUNT     MNT_UPDATE
#define MS_NOATIME     MNT_NOATIME
#endif
#elif defined(__linux__)
#define MS_RDONLY      1
#define MS_NOSUID      2
#define MS_NODEV       4
#define MS_NOEXEC      8
#define MS_SYNCHRONOUS 16
#define MS_REMOUNT     32
#define MS_MANDLOCK    64
#define MS_DIRSYNC     128
#define MS_NOSYMFOLLOW 256
#define MS_NOATIME     1024
#define MS_NODIRATIME  2048
#define MS_BIND        4096
#define MS_MOVE        8192
#define MS_REC         16384
#define MS_SILENT      32768
#define MS_POSIXACL    (1<<16)
#define MS_UNBINDABLE  (1<<17)
#define MS_PRIVATE     (1<<18)
#define MS_SLAVE       (1<<19)
#define MS_SHARED      (1<<20)
#define MS_RELATIME    (1<<21)
#define MS_KERNMOUNT   (1<<22)
#define MS_I_VERSION   (1<<23)
#define MS_STRICTATIME (1<<24)
#define MS_LAZYTIME    (1<<25)
#define MS_NOREMOTELOCK (1<<27)
#define MS_NOSEC       (1<<28)
#define MS_BORN        (1<<29)
#define MS_ACTIVE      (1<<30)
#define MS_NOUSER      (1U<<31)
#endif

#if defined(__linux__)
#define MS_RMT_MASK (MS_RDONLY|MS_SYNCHRONOUS|MS_MANDLOCK|MS_I_VERSION|MS_LAZYTIME)

#define MS_MGC_VAL 0xc0ed0000
#define MS_MGC_MSK 0xffff0000

#define MNT_FORCE       1
#define MNT_DETACH      2
#define MNT_EXPIRE      4
#define UMOUNT_NOFOLLOW 8
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
int mount(const char *, const char *, int, void *);
int unmount(const char *, int);
#elif defined(__linux__)
int mount(const char *, const char *, const char *, unsigned long, const void *);
#endif
#if defined(__HyperbolaBSD__) || defined(__linux__)
int umount(const char *);
int umount2(const char *, int);
#endif

#ifdef __cplusplus
}
#endif

#endif
