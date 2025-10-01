#ifndef _SYS_REBOOT_H
#define _SYS_REBOOT_H
#ifdef __cplusplus
extern "C" {
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define RB_AUTOBOOT     0
#elif defined(__linux__)
#define RB_AUTOBOOT     0x01234567
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define RB_ASKNAME      0x00000001
#define RB_SINGLE       0x00000002
#define RB_NOSYNC       0x00000004
#define RB_HALT         0x00000008
#define RB_INITNAME     0x00000010
#define RB_DFLTROOT     0x00000020
#define RB_KDB          0x00000040
#define RB_RDONLY       0x00000080
#define RB_DUMP         0x00000100
#define RB_MINIROOT     0x00000200
#define RB_CONFIG       0x00000400
#define RB_TIMEBAD      0x00000800
#define RB_POWERDOWN    0x00001000
#define RB_SERCONS      0x00002000
#define RB_USERREQ      0x00004000
#define RB_RESET        0x00008000
#define RB_GOODRANDOM   0x00010000
#if defined(__HyperbolaBSD__)
#define RB_HALT_SYSTEM  RB_HALT
#define RB_POWER_OFF    RB_POWERDOWN
#endif
#elif defined(__linux__)
#define RB_HALT_SYSTEM  0xcdef0123
#define RB_ENABLE_CAD   0x89abcdef
#define RB_DISABLE_CAD  0
#define RB_POWER_OFF    0x4321fedc
#define RB_SW_SUSPEND   0xd000fce2
#define RB_KEXEC        0x45584543
#endif

int reboot(int);

#ifdef __cplusplus
}
#endif
#endif
