struct semid_ds {
	struct ipc_perm sem_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	struct sem *sem_base;
	unsigned short sem_nsems;
#elif defined(__linux__)
	unsigned long __sem_otime_lo;
	unsigned long __sem_otime_hi;
	unsigned long __sem_ctime_lo;
	unsigned long __sem_ctime_hi;
	unsigned short sem_nsems;
	char __sem_nsems_pad[sizeof(long)-sizeof(short)];
	long __unused3;
	long __unused4;
#endif
	time_t sem_otime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long __unused1;
#endif
	time_t sem_ctime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	long __unused3;
	long __unused4[4];
#endif
};
