struct semid_ds {
	struct ipc_perm sem_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct sem *sem_base;
	unsigned short sem_nsems;
#endif
	time_t sem_otime;
	long long __unused1;
	time_t sem_ctime;
	long long __unused2;
#if defined(__linux__)
	unsigned short sem_nsems;
	char __sem_nsems_pad[sizeof(long long)-sizeof(short)];
#endif
	long long __unused3;
	long long __unused4;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long long __unused5[2];
#endif
};
