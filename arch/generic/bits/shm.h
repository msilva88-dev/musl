#define SHMLBA 4096

struct shmid_ds {
	struct ipc_perm shm_perm;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	int shm_segsz;
	pid_t shm_lpid;
	pid_t shm_cpid;
	shmatt_t shm_nattch;
#elif defined(__linux__)
	size_t shm_segsz;
#endif
	time_t shm_atime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long __pad1;
#endif
	time_t shm_dtime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long __pad2;
#endif
	time_t shm_ctime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long __pad3;
	void *shm_internal;
#elif defined(__linux__)
	pid_t shm_cpid;
	pid_t shm_lpid;
	unsigned long shm_nattch;
	unsigned long __pad1;
	unsigned long __pad2;
#endif
};

#if defined(__linux__)
struct shminfo {
	unsigned long shmmax, shmmin, shmmni, shmseg, shmall, __unused[4];
};

struct shm_info {
	int __used_ids;
	unsigned long shm_tot, shm_rss, shm_swp;
	unsigned long __swap_attempts, __swap_successes;
};
#endif
