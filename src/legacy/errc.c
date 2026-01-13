#define _BSD_SOURCE
#include <err.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

extern char *__progname;

void vwarnc(int code, const char *fmt, va_list ap)
{
	fprintf (stderr, "%s: ", __progname);
	if (fmt) {
		vfprintf(stderr, fmt, ap);
		fputs (": ", stderr);
	}
	fputs(strerror(code), stderr);
	fputc('\n', stderr);
}

_Noreturn void verrc(int status, int code, const char *fmt, va_list ap)
{
	vwarnc(code, fmt, ap);
	exit(status);
}

void warnc(int code, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vwarnc(code, fmt, ap);
	va_end(ap);
}

_Noreturn void errc(int status, int code, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	verrc(status, code, fmt, ap);
	va_end(ap);
}
