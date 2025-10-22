struct ipc_perm {
#if defined(__linux__)
	key_t __ipc_perm_key;
	uid_t uid;
	gid_t gid;
#endif
	uid_t cuid;
	gid_t cgid;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	uid_t uid;
	gid_t gid;
#endif
	mode_t mode;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned short __ipc_perm_seq;
	key_t __ipc_perm_key;
#elif defined(__linux__)
	int __ipc_perm_seq;
	long __pad1;
	long __pad2;
#endif
};
