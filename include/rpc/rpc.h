#ifndef _RPC_RPC_H
#define _RPC_RPC_H

#ifdef __cplusplus
extern "C" {
#endif

#include <netinet/in.h>
#include <rpc/auth.h>
#include <rpc/auth_unix.h>
#include <rpc/clnt.h>
#include <rpc/pmap_clnt.h>
#include <rpc/rpc_msg.h>
#include <rpc/svc.h>
#include <rpc/types.h>
#include <rpc/xdr.h>

struct rpcent {
	char **r_aliases, *r_name;
	int r_number;
}

#ifdef _BSD_SOURCE
int callrpc(char *, int, int, int, xdrproc_t, char *, xdrproc_t , char *);
void endrpcent(void);
int get_myaddress(struct sockaddr_in *);
struct rpcent *getrpcbyname(char *);
struct rpcent *getrpcbynumber(int);
struct rpcent *getrpcent(void);
int getrpcport(char *, int, int, int);
int registerrpc(int, int, int, char *(*)(), xdrproc_t, xdrproc_t);
void setrpcent(int);
bool_t xdr_opaque_auth(XDR *, struct opaque_auth *);
#endif

#ifdef __cplusplus
}
#endif

#endif
