#define _GNU_SOURCE
#if defined(__HyperbolaBSD__)
#include <sys/event.h>
#include <sys/mman.h>
#include <sys/time.h>
#endif
#include <sys/sem.h>
#include <errno.h>
#if defined(__HyperbolaBSD__)
#include <fcntl.h>
#include <stddef.h>
#include <unistd.h>
#elif defined(__linux__)
#include "syscall.h"
#include "ipc.h"
#endif

#if defined(__HyperbolaBSD__)
#define MAX_SEM_IDS 10
#define MAX_SEMS_TOTAL 60
#define MAX_SEMOPS 100

typedef struct {
	int used;
	int val;
	int kq;
} bsd_sem_t;

static bsd_sem_t *get_shared_sems(void)
{
	static bsd_sem_t *sems = NULL;
	static int initialized = 0;

	if (!initialized) {
		int fd = shm_open("/bsd_semtimedop_shm", O_CREAT | O_RDWR, 0666);
		if (fd == -1) return NULL;

		ftruncate(fd, sizeof(bsd_sem_t) * MAX_SEMS_TOTAL);

		sems = mmap(
			NULL,
			sizeof(bsd_sem_t) * MAX_SEMS_TOTAL,
			PROT_READ | PROT_WRITE,
			MAP_SHARED,
			fd,
			0
		);

		close(fd);
		if (sems == MAP_FAILED) return NULL;

		for (int i = 0; i < MAX_SEMS_TOTAL; i++) {
			sems[i].used = 0;
			sems[i].val = 0;
			sems[i].kq = 0;
		}

		initialized = 1;
	}

	return sems;
}

static bsd_sem_t *init_sem(int id, int initial_val, int *first_time)
{
	if (id < 0 || id >= MAX_SEM_IDS) {
		errno = EINVAL;
		return NULL;
	}

	bsd_sem_t *sems = get_shared_sems();
	if (!sems) return NULL;

	int total = 0;
	for (int i = 0; i < MAX_SEMS_TOTAL; i++)
		if (sems[i].used) total++;
	if (total >= MAX_SEMS_TOTAL) {
		errno = ENOSPC;
		return NULL;
	}

	bsd_sem_t *sem = &sems[id];
	if (!sem->used) {
		sem->val = initial_val;
		sem->kq = kqueue();
		if (sem->kq == -1) return NULL;

		struct kevent kev;
		EV_SET(&kev, 1, EVFILT_USER, EV_ADD | EV_CLEAR, 0, 0, NULL);
		if (kevent(sem->kq, &kev, 1, NULL, 0, NULL) == -1) return NULL;

		sem->used = 1;
		if (first_time) *first_time = 1;
	} else {
		if (first_time) *first_time = 0;
	}

	return sem;
}
#elif defined(__linux__)
#define IS32BIT(x) !((x)+0x80000000ULL>>32)
#define CLAMP(x) (int)(IS32BIT(x) ? (x) : 0x7fffffffU+((0ULL+(x))>>63))

#if !defined(SYS_semtimedop) && !defined(SYS_ipc) || \
	SYS_semtimedop == SYS_semtimedop_time64
#define NO_TIME32 1
#else
#define NO_TIME32 0
#endif
#endif

int semtimedop(int id, struct sembuf *buf, size_t n, const struct timespec *ts)
{
#if defined(__HyperbolaBSD__)
	if (n > MAX_SEMOPS) {
		errno = E2BIG;
		return -1;
	}

	int first_time = 0;
	bsd_sem_t *sem = init_sem(id, 1, &first_time);
	if (!sem) return -1;

	struct kevent kev;
	for (size_t i = 0; i < n; i++) {
		int op = buf[i].sem_op;

		if (op < 0) { // wait / P
			while (sem->val + op < 0) {
				int ret = kevent(sem->kq, NULL, 0, &kev, 1, ts);
				if (ret == 0) return -1; // timeout
				if (ret < 0) return -1;  // error
			}
			sem->val += op;
		} else if (op > 0) { // signal / V
			sem->val += op;
			EV_SET(&kev, 1, EVFILT_USER, 0, NOTE_TRIGGER, 0, NULL);
			kevent(sem->kq, &kev, 1, NULL, 0, NULL);
		}
	}

	return 0;
#elif defined(__linux__)
#ifdef SYS_semtimedop_time64
	time_t s = ts ? ts->tv_sec : 0;
	long ns = ts ? ts->tv_nsec : 0;
	int r = -ENOSYS;
	if (NO_TIME32 || !IS32BIT(s))
		r = __syscall(SYS_semtimedop_time64, id, buf, n,
			ts ? ((long long[]){s, ns}) : 0);
	if (NO_TIME32 || r!=-ENOSYS) return __syscall_ret(r);
	ts = ts ? (void *)(long[]){CLAMP(s), ns} : 0;
#endif
#if defined(SYS_ipc)
	return syscall(SYS_ipc, IPCOP_semtimedop, id, n, 0, buf, ts);
#elif defined(SYS_semtimedop)
	return syscall(SYS_semtimedop, id, buf, n, ts);
#else
	return __syscall_ret(-ENOSYS);
#endif
#endif
}
