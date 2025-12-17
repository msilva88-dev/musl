#ifndef _RPC_PMAP_CLNT_H
#define _RPC_PMAP_CLNT_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _BSD_SOURCE
enum clnt_stat clnt_broadcast(unsigned long, unsigned long, unsigned long,
	xdrproc_t, char *, xdrproc_t, char *,
	bool_t (*)(caddr_t, struct sockaddr_in *));
struct pmaplist *pmap_getmaps(struct sockaddr_in *);
unsigned short pmap_getport(struct sockaddr_in *, unsigned long,
	unsigned long, unsigned int);
enum clnt_stat pmap_rmtcall(struct sockaddr_in *, unsigned long,
	unsigned long, unsigned long, xdrproc_t, caddr_t, xdrproc_t, caddr_t,
	struct timeval, unsigned long *);
bool_t pmap_set(unsigned long, unsigned long, unsigned int, int);
bool_t pmap_unset(unsigned long, unsigned long);
#endif

#ifdef __cplusplus
}
#endif

#endif
