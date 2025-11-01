#ifndef _ERR_H
#define _ERR_H

#include <features.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

void warn(const char *, ...);
void vwarn(const char *, va_list);
void warnx(const char *, ...);
void vwarnx(const char *, va_list);
#ifdef _BSD_SOURCE
void warnc(int, const char *, ...);
void vwarnc(int, const char *, va_list);
#endif

_Noreturn void err(int, const char *, ...);
_Noreturn void verr(int, const char *, va_list);
_Noreturn void errx(int, const char *, ...);
_Noreturn void verrx(int, const char *, va_list);
#ifdef _BSD_SOURCE
_Noreturn void errc(int, int, const char *, ...);
_Noreturn void verrc(int, int, const char *, va_list);
#endif

#ifdef __cplusplus
}
#endif

#endif
