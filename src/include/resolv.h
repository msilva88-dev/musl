#ifndef RESOLV_H
#define RESOLV_H

#include "../../include/resolv.h"

hidden int __dn_expand(const unsigned char *, const unsigned char *, const unsigned char *, char *, int);

hidden int __res_mkquery(int, const char *, int, int, const unsigned char *, int, const unsigned char*, unsigned char *, int);
hidden int __res_send(const unsigned char *, int, unsigned char *, int);
hidden int __res_msend(int, const unsigned char *const *, const int *, unsigned char *const *, int *, int);

hidden int __res_hnok(const char *);
hidden int res_hnok(const char *);
/*
hidden int res_dnok(const char *);
hidden int res_ownok(const char *);
hidden int res_mailok(const char *);
*/

hidden u_int16_t _getshort(const unsigned char *);
hidden u_int32_t _getlong(const unsigned char *);
/*
hidden void __putlong(u_int32_t, unsigned char *);
hidden void __putshort(u_int16_t, unsigned char *);
*/

#endif
