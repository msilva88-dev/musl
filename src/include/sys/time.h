#ifndef SYS_TIME_H
#define SYS_TIME_H

#include "../../../include/sys/time.h"

#if defined(__linux__)
hidden int __futimesat(int, const char *, const struct timeval [2]);
#endif

#endif
