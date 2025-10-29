#ifndef _TTYENT_H
#define _TTYENT_H

#ifdef __cplusplus
extern "C" {
#endif

#include <paths.h>

#define __TTYSNAME(ttye) ( \
	(ttye) >= 0 && (ttye) <= TTY_MDMBUF \
	? ((const char *[]){ \
		[0] = "off", \
		[TTY_ON] = "on", \
		[TTY_SECURE] = "secure", \
		[TTY_LOCAL] = "local", \
		[TTY_RTSCTS] = "rtscts", \
		[TTY_SOFTCAR] = "softcar", \
		[TTY_MDMBUF] = "mdmbuf", \
	}[(ttye)]) \
	: "window" \
	)

enum __ttyent_e {
	TTY_ON = 001,
	TTY_SECURE = 002,
	TTY_LOCAL = 004,
	TTY_RTSCTS = 010,
	TTY_SOFTCAR = 020,
	TTY_MDMBUF = 040
};

#define _TTYS_OFF __TTYSNAME(0)
#define _TTYS_ON __TTYSNAME(TTY_ON)
#define _TTYS_SECURE __TTYSNAME(TTY_SECURE)
#define _TTYS_LOCAL __TTYSNAME(TTY_LOCAL)
#define _TTYS_RTSCTS __TTYSNAME(TTY_RTSCTS)
#define _TTYS_SOFTCAR __TTYSNAME(TTY_SOFTCAR)
#define _TTYS_MDMBUF __TTYSNAME(TTY_MDMBUF)
#define _TTYS_WINDOW __TTYSNAME(-1)

struct ttyent {
	char *ty_name, *ty_getty, *ty_type;
	int ty_status;
	char *ty_window, *ty_comment;
};

#ifdef _BSD_SOURCE
struct ttyent *getttynam(const char *);
struct ttyent *getttyent(void);
int setttyent(void);
int endttyent(void);
#endif

#ifdef __cplusplus
}
#endif

#endif
