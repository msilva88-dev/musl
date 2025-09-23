#ifndef _SYS_SYSARCH_H
#define _SYS_SYSARCH_H

#include <bits/sysarch.h>

#if defined(__i386__)
struct i386_iopl_args {
#elif defined(__x86_64__)
struct amd64_iopl_args {
#endif
        int iopl;
};

#if defined(__i386__)
int i386_get_fsbase(void **);
int i386_get_gsbase(void **);
int i386_iopl(int);
int i386_set_fsbase(void *);
int i386_set_gsbase(void *);
#elif defined(__x86_64__)
int amd64_iopl(int);
#endif

int sysarch(int, void *);

#endif
