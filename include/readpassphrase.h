#ifndef _READPASSPHRASE_H
#define _READPASSPHRASE_H

#ifdef __cplusplus
extern "C" {
#endif

enum __rdpsp_e {
	RPP_ECHO_OFF = 000,
	RPP_ECHO_ON = 001,
	RPP_REQUIRE_TTY = 002,
	RPP_FORCELOWER = 004,
	RPP_FORCEUPPER = 010,
	RPP_SEVENBIT = 020,
	RPP_STDIN = 040
};

#ifdef _BSD_SOURCE
char * readpassphrase(const char *, char *, size_t, int);
#endif

#ifdef __cplusplus
}
#endif

#endif
