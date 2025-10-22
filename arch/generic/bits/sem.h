struct semid_ds {
	struct ipc_perm sem_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct sem *sem_base;
	unsigned short sem_nsems;
#endif
	time_t sem_otime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long __unused1;
#endif
	time_t sem_ctime;
#if defined(__linux__)
#if __BYTE_ORDER == __LITTLE_ENDIAN
	unsigned short sem_nsems;
	char __sem_nsems_pad[sizeof(long)-sizeof(short)];
#else
	char __sem_nsems_pad[sizeof(long)-sizeof(short)];
	unsigned short sem_nsems;
#endif
#endif
	long __unused3;
	long __unused4;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long __unused5[3];
#endif
};
