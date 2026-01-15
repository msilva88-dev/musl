#ifndef _NET_IF_DL_H
#define _NET_IF_DL_H

#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_uint16_t

#include <bits/alltypes.h>
#include <sys/socket.h>
#include <sys/types.h>

#define _SDL_DATA_LEN 24
struct sockaddr_dl {
	unsigned char sdl_len, sdl_family;
	uint16_t sdl_index;
        unsigned char sdl_type, sdl_nlen, sdl_alen, sdl_slen;
        char sdl_data[_SDL_DATA_LEN];
};

#define LLADDR(sdl) (caddr_t)((sdl)->sdl_nlen + (sdl)->sdl_data)

#ifdef _BSD_SOURCE
char *link_ntoa_r(const struct sockaddr_dl *, char *, size_t);
char *link_ntoa(const struct sockaddr_dl *);
#endif

#ifdef __cplusplus
}
#endif

#endif
