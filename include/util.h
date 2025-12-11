#ifndef _UTIL_H
#define _UTIL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <pty.h>
#include <utmp.h>

int pidfile(const char *);

#ifdef __cplusplus
}
#endif

#endif
