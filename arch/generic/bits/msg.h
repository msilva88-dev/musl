struct msqid_ds {
	struct ipc_perm msg_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct msg *msg_first;
	struct msg *msg_last;
	unsigned long msg_cbytes;
	msgqnum_t msg_qnum;
	msglen_t msg_qbytes;
	pid_t msg_lspid;
	pid_t msg_lrpid;
#endif
	time_t msg_stime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long long __unused1;
#endif
	time_t msg_rtime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long long __unused2;
#endif
	time_t msg_ctime;
#if defined(__linux__)
	unsigned long msg_cbytes;
	msgqnum_t msg_qnum;
	msglen_t msg_qbytes;
	pid_t msg_lspid;
	pid_t msg_lrpid;
#endif
	unsigned long __unused[2];
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long __unused3[3];
#endif
};
