struct msqid_ds {
	struct ipc_perm msg_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct msg *msg_first;
	struct msg *msg_last;
#elif defined(__linux__)
	unsigned long __msg_stime_lo;
	unsigned long __msg_stime_hi;
	unsigned long __msg_rtime_lo;
	unsigned long __msg_rtime_hi;
	unsigned long __msg_ctime_lo;
	unsigned long __msg_ctime_hi;
#endif
	unsigned long msg_cbytes;
	msgqnum_t msg_qnum;
	msglen_t msg_qbytes;
	pid_t msg_lspid;
	pid_t msg_lrpid;
#if defined(__linux__)
	unsigned long __unused[2];
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
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long __unused3[5];
#endif
};
