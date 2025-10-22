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
	unsigned long long __pad1;
#endif
	time_t shm_dtime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long long __pad2;
#endif
	time_t shm_ctime;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	unsigned long long __pad3;
	void *shm_internal;
#elif defined(__linux__)
	pid_t shm_cpid;
	pid_t shm_lpid;
	unsigned long shm_nattch;
	unsigned long __pad0;
	unsigned long long __pad1;
	unsigned long long __pad2;
#endif
};

#if defined(__linux__)
struct shminfo {
	unsigned long shmmax, __pad0, shmmin, __pad1, shmmni, __pad2,
	              shmseg, __pad3, shmall, __pad4;
	unsigned long long __unused[4];
};

struct shm_info {
	int __used_ids;
	int __pad_ids;
	unsigned long shm_tot, __pad0, shm_rss, __pad1, shm_swp, __pad2;
	unsigned long __swap_attempts, __pad3, __swap_successes, __pad4;
}
#ifdef __GNUC__
__attribute__((__aligned__(8)))
#endif
;
#endif
