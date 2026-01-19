#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#endif
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <sys/resource.h>
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include <sys/sem.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <grp.h>
#include <pthread.h>
#include <pwd.h>
#include <stdio.h>
#endif
#include <signal.h>
#if defined(__linux__)
#include <sys/sysinfo.h>
#include <sys/auxv.h>
#endif
#include "syscall.h"
#include "libc.h"

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static inline rlimit_t __getrlimit_sysconf(int val, char shrt)
{
	struct rlimit rl;
	if (getrlimit(val, &rl)) return -1;
	if (rl.rlim_cur == RLIM_INFINITY) return -1;
	if (rl.rlim_cur > LONG_MAX) {
		errno = EOVERFLOW;
		return -1;
	}
	if (rl.rlim_cur > SHRT_MAX && shrt == 1) return SHRT_MAX;
	return rl.rlim_cur;
}

static inline int __sysctl_sysconf(int tlmane, int slname, char zerocond)
{
	int mib[] = {tlname, slname}, r = 0, value = 0;
	size_t len = sizeof(value);
	r = __syscall(SYS_sysctl, mib, 2, &value, &len, NULL, 0);
	if (r == -1) return -1;
	else if (value == 0 && zerocond == 1) return -1;
	else return value;
}

static inline int64_t __sysctl_physpages(int slname)
{
	int mib[] = {
		(slname == HW_PHYSMEM64) ? CTL_HW : CTL_VM,
		(slname == HW_PHYSMEM64) ? HW_PHYSMEM64 : VM_UVMEXP
	};
	long r = 0;
	if (slname == HW_PHYSMEM64) {
		int64_t physmem = 0;
		size_t len = sizeof(physmem);
		r = __syscall(SYS_sysctl, mib, 2, &physmem, &len, NULL, 0);
	} else {
		struct uvmexp uvmexp;
		size_t len = sizeof(uvmexp);
		r = __syscall(SYS_sysctl, mib, 2, &uvmexp, &len, NULL, 0);
	}
	if (r == -1) return -1;
	if (slname == HW_PHYSMEM64) return physmem/getpagesize();
	else return uvmexp.free;
}

static inline long __ipv6_sysconf(void)
{
	if (!_POSIX_IPV6) {
		int sverrno = errno, value = socket(PF_INET6, SOCK_DGRAM, 0);

		errno = sverrno;
		if (value >= 0) {
			close(value);
			return 200112L;
		}
		return 0;
	}

	return _POSIX_IPV6;
}

#define _CHAR_SIZE(type) (sizeof((type)) * CHAR_BIT)
#if !_POSIX_V6_ILP32_OFFBIG || !_POSIX_V7_ILP32_OFFBIG
#define _VAL_ILP32 (( \
	_CHAR_SIZE(int) == 32 && _CHAR_SIZE(long) == 32 \
	&& _CHAR_SIZE(void *) == 32 && _CHAR_SIZE(off_t) >= 64 \
) ? 1 : -1)
#else
#define _VAL_ILP32
#endif
#if !_POSIX_V6_LP64_OFF64 || !_POSIX_V7_LP64_OFF64
#define _VAL_LP64 (( \
	_CHAR_SIZE(int) == 32 && _CHAR_SIZE(long) == 64 \
	&& _CHAR_SIZE(void *) == 64 && _CHAR_SIZE(off_t) == 64 \
) ? 1 : -1)
#else
#define _VAL_LP64
#endif
#if !_POSIX_V6_LPBIG_OFFBIG || !_POSIX_V7_LPBIG_OFFBIG
#define _VAL_LPBIG (( \
	_CHAR_SIZE(int) >= 32 && _CHAR_SIZE(long) >= 64 \
	&& _CHAR_SIZE(void *) >= 64 && _CHAR_SIZE(off_t) >= 64 \
) ? 1 : -1)
#else
#define _VAL_LPBIG
#endif
#elif defined(__linux__)
#define JT(x) (-256|(x))
#define VER JT(1)
#define JT_ARG_MAX JT(2)
#define JT_MQ_PRIO_MAX JT(3)
#define JT_PAGE_SIZE JT(4)
#define JT_SEM_VALUE_MAX JT(5)
#define JT_NPROCESSORS_CONF JT(6)
#define JT_NPROCESSORS_ONLN JT(7)
#define JT_PHYS_PAGES JT(8)
#define JT_AVPHYS_PAGES JT(9)
#define JT_ZERO JT(10)
#define JT_DELAYTIMER_MAX JT(11)
#define JT_MINSIGSTKSZ JT(12)
#define JT_SIGSTKSZ JT(13)

#define RLIM(x) (-32768|(RLIMIT_ ## x))
#endif

long sysconf(int name)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	static const long values[] = {
		[_SC_ARG_MAX] = __sysctl_sysconf(CTL_KERN, KERN_ARGMAX, 0),
		[_SC_CHILD_MAX] = __getrlimit_sysconf(RLIMIT_NPROC, 0),
		[_SC_CLK_TCK] = CLK_TCK,
		[_SC_NGROUPS_MAX] = __sysctl_sysconf(CTL_KERN, KERN_NGROUPS, 0),
		[_SC_OPEN_MAX] = __getrlimit_sysconf(RLIMIT_NOFILE, 0),
		[_SC_STREAM_MAX] = __getrlimit_sysconf(RLIMIT_NOFILE, 1),
		[_SC_TZNAME_MAX] = NAME_MAX,
		[_SC_JOB_CONTROL] = _POSIX_JOB_CONTROL,
		[_SC_SAVED_IDS] = _POSIX_SAVED_IDS,
		[_SC_REALTIME_SIGNALS] = _POSIX_REALTIME_SIGNALS,
		[_SC_PRIORITY_SCHEDULING] = _POSIX_PRIORITY_SCHEDULING,
		[_SC_TIMERS] = _POSIX_TIMERS,
		[_SC_ASYNCHRONOUS_IO] = _POSIX_ASYNCHRONOUS_IO,
		[_SC_PRIORITIZED_IO] = _POSIX_PRIORITIZED_IO,
		[_SC_SYNCHRONIZED_IO] = _POSIX_SYNCHRONIZED_IO,
		[_SC_FSYNC] = _POSIX_FSYNC,
		[_SC_MAPPED_FILES] = _POSIX_MAPPED_FILES,
		[_SC_MEMLOCK] = _POSIX_MEMLOCK,
		[_SC_MEMLOCK_RANGE] = _POSIX_MEMLOCK_RANGE,
		[_SC_MEMORY_PROTECTION] = _POSIX_MEMORY_PROTECTION,
		[_SC_MESSAGE_PASSING] = _POSIX_MESSAGE_PASSING,
		[_SC_SEMAPHORES] = _POSIX_SEMAPHORES,
		[_SC_SHARED_MEMORY_OBJECTS] = _POSIX_SHARED_MEMORY_OBJECTS,
#elif defined(__linux__)
	static const short values[] = {
		[_SC_ARG_MAX] = JT_ARG_MAX,
		[_SC_CHILD_MAX] = RLIM(NPROC),
		[_SC_CLK_TCK] = 100,
		[_SC_NGROUPS_MAX] = 32,
		[_SC_OPEN_MAX] = RLIM(NOFILE),
		[_SC_STREAM_MAX] = -1,
		[_SC_TZNAME_MAX] = TZNAME_MAX,
		[_SC_JOB_CONTROL] = 1,
		[_SC_SAVED_IDS] = 1,
		[_SC_REALTIME_SIGNALS] = VER,
		[_SC_PRIORITY_SCHEDULING] = -1,
		[_SC_TIMERS] = VER,
		[_SC_ASYNCHRONOUS_IO] = VER,
		[_SC_PRIORITIZED_IO] = -1,
		[_SC_SYNCHRONIZED_IO] = -1,
		[_SC_FSYNC] = VER,
		[_SC_MAPPED_FILES] = VER,
		[_SC_MEMLOCK] = VER,
		[_SC_MEMLOCK_RANGE] = VER,
		[_SC_MEMORY_PROTECTION] = VER,
		[_SC_MESSAGE_PASSING] = VER,
		[_SC_SEMAPHORES] = VER,
		[_SC_SHARED_MEMORY_OBJECTS] = VER,
#endif
		[_SC_AIO_LISTIO_MAX] = -1,
		[_SC_AIO_MAX] = -1,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_AIO_PRIO_DELTA_MAX] = -1,
		[_SC_DELAYTIMER_MAX] = -1,
#elif defined(__linux__)
		[_SC_AIO_PRIO_DELTA_MAX] = JT_ZERO, /* ?? */
		[_SC_DELAYTIMER_MAX] = JT_DELAYTIMER_MAX,
#endif
#if defined(__linux__)
		[_SC_MQ_OPEN_MAX] = -1,
		[_SC_MQ_PRIO_MAX] = JT_MQ_PRIO_MAX,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_VERSION] = __sysctl_sysconf(CTL_KERN, KERN_POSIX1, 0),
		[_SC_PAGE_SIZE] = PAGE_SIZE ? PAGE_SIZE : __sysctl_sysconf(CTL_HW, HW_PAGESIZE, 0),
#elif defined(__linux__)
		[_SC_VERSION] = VER,
		[_SC_PAGE_SIZE] = JT_PAGE_SIZE,
#endif
#if defined(__linux__)
		[_SC_RTSIG_MAX] = _NSIG - 1 - 31 - 3,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_SEM_NSEMS_MAX] = -1,
		[_SC_SEM_VALUE_MAX] = SEM_VALUE_MAX,
#elif defined(__linux__)
		[_SC_SEM_NSEMS_MAX] = SEM_NSEMS_MAX,
		[_SC_SEM_VALUE_MAX] = JT_SEM_VALUE_MAX,
#endif
		[_SC_SIGQUEUE_MAX] = -1,
		[_SC_TIMER_MAX] = -1,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_BC_BASE_MAX] = BC_BASE_MAX,
		[_SC_BC_DIM_MAX] = BC_DIM_MAX,
		[_SC_BC_SCALE_MAX] = BC_SCALE_MAX,
		[_SC_BC_STRING_MAX] = BC_STRING_MAX,
#elif defined(__linux__)
		[_SC_BC_BASE_MAX] = _POSIX2_BC_BASE_MAX,
		[_SC_BC_DIM_MAX] = _POSIX2_BC_DIM_MAX,
		[_SC_BC_SCALE_MAX] = _POSIX2_BC_SCALE_MAX,
		[_SC_BC_STRING_MAX] = _POSIX2_BC_STRING_MAX,
#endif
		[_SC_COLL_WEIGHTS_MAX] = COLL_WEIGHTS_MAX,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_EXPR_NEST_MAX] = EXPR_NEST_MAX,
		[_SC_LINE_MAX] = LINE_MAX,
#elif defined(__linux__)
		[_SC_EXPR_NEST_MAX] = -1,
		[_SC_LINE_MAX] = -1,
#endif
		[_SC_RE_DUP_MAX] = RE_DUP_MAX,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_2_VERSION] = _POSIX2_VERSION,
		[_SC_2_C_BIND] = _POSIX2_C_BIND,
		[_SC_2_C_DEV] = _POSIX2_C_DEV,
		[_SC_2_FORT_DEV] = _POSIX2_FORT_DEV,
		[_SC_2_FORT_RUN] = _POSIX2_FORT_RUN,
		[_SC_2_SW_DEV] = _POSIX2_SW_DEV,
		[_SC_2_LOCALEDEF] = _POSIX2_LOCALEDEF,
#elif defined(__linux__)
		[_SC_2_VERSION] = VER,
		[_SC_2_C_BIND] = VER,
		[_SC_2_C_DEV] = -1,
		[_SC_2_FORT_DEV] = -1,
		[_SC_2_FORT_RUN] = -1,
		[_SC_2_SW_DEV] = -1,
		[_SC_2_LOCALEDEF] = -1,
#endif
		[_SC_IOV_MAX] = IOV_MAX,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_THREADS] = _POSIX_THREADS,
		[_SC_THREAD_SAFE_FUNCTIONS] = _POSIX_THREAD_SAFE_FUNCTIONS,
		[_SC_GETGR_R_SIZE_MAX] = _GR_BUF_LEN,
		[_SC_GETPW_R_SIZE_MAX] = _PW_BUF_LEN,
		[_SC_LOGIN_NAME_MAX] = LOGIN_NAME_MAX,
#elif defined(__linux__)
		[_SC_THREADS] = VER,
		[_SC_THREAD_SAFE_FUNCTIONS] = VER,
		[_SC_GETGR_R_SIZE_MAX] = -1,
		[_SC_GETPW_R_SIZE_MAX] = -1,
		[_SC_LOGIN_NAME_MAX] = 256,
#endif
		[_SC_TTY_NAME_MAX] = TTY_NAME_MAX,
		[_SC_THREAD_DESTRUCTOR_ITERATIONS] = PTHREAD_DESTRUCTOR_ITERATIONS,
		[_SC_THREAD_KEYS_MAX] = PTHREAD_KEYS_MAX,
		[_SC_THREAD_STACK_MIN] = PTHREAD_STACK_MIN,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_THREAD_THREADS_MAX] = PTHREAD_THREADS_MAX,
		[_SC_THREAD_ATTR_STACKADDR] = _POSIX_THREAD_ATTR_STACKADDR,
		[_SC_THREAD_ATTR_STACKSIZE] = _POSIX_THREAD_ATTR_STACKSIZE,
		[_SC_THREAD_PRIORITY_SCHEDULING] = _POSIX_THREAD_PRIORITY_SCHEDULING,
		[_SC_THREAD_PRIO_INHERIT] = _POSIX_THREAD_PRIO_INHERIT,
		[_SC_THREAD_PRIO_PROTECT] = _POSIX_THREAD_PRIO_PROTECT,
		[_SC_THREAD_PROCESS_SHARED] = _POSIX_THREAD_PROCESS_SHARED,
		[_SC_NPROCESSORS_CONF] = __sysctl_sysconf(CTL_HW, HW_NCPU, 0),
		[_SC_NPROCESSORS_ONLN] = __sysctl_sysconf(CTL_HW, HW_NCPUONLINE, 0),
		[_SC_PHYS_PAGES] = __sysctl_physpages(HW_PHYSMEM64),
		[_SC_AVPHYS_PAGES] = __sysctl_physpages(VM_UVMEXP),
#elif defined(__linux__)
		[_SC_THREAD_THREADS_MAX] = -1,
		[_SC_THREAD_ATTR_STACKADDR] = VER,
		[_SC_THREAD_ATTR_STACKSIZE] = VER,
		[_SC_THREAD_PRIORITY_SCHEDULING] = VER,
		[_SC_THREAD_PRIO_INHERIT] = -1,
		[_SC_THREAD_PRIO_PROTECT] = -1,
		[_SC_THREAD_PROCESS_SHARED] = VER,
		[_SC_NPROCESSORS_CONF] = JT_NPROCESSORS_CONF,
		[_SC_NPROCESSORS_ONLN] = JT_NPROCESSORS_ONLN,
		[_SC_PHYS_PAGES] = JT_PHYS_PAGES,
		[_SC_AVPHYS_PAGES] = JT_AVPHYS_PAGES,
#endif
		[_SC_ATEXIT_MAX] = -1,
#if defined(__linux__)
		[_SC_PASS_MAX] = -1,
#endif
		[_SC_XOPEN_VERSION] = _XOPEN_VERSION,
#if defined(__linux__)
		[_SC_XOPEN_XCU_VERSION] = _XOPEN_VERSION,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_XOPEN_UNIX] = _XOPEN_UNIX,
		[_SC_XOPEN_CRYPT] = _XOPEN_CRYPT,
		[_SC_XOPEN_ENH_I18N] = _XOPEN_ENH_I18N,
		[_SC_XOPEN_SHM] = __sysctl_sysconf(CTL_KERN, KERN_SYSVSHM, 1),
		[_SC_2_CHAR_TERM] = _POSIX2_CHAR_TERM,
		[_SC_2_UPE] = _POSIX2_UPE,
#elif defined(__linux__)
		[_SC_XOPEN_UNIX] = 1,
		[_SC_XOPEN_CRYPT] = -1,
		[_SC_XOPEN_ENH_I18N] = 1,
		[_SC_XOPEN_SHM] = 1,
		[_SC_2_CHAR_TERM] = -1,
		[_SC_2_UPE] = -1,
#endif
#if defined(__linux__)
		[_SC_XOPEN_XPG2] = -1,
		[_SC_XOPEN_XPG3] = -1,
		[_SC_XOPEN_XPG4] = -1,
		[_SC_NZERO] = NZERO,
		[_SC_XBS5_ILP32_OFF32] = -1,
		[_SC_XBS5_ILP32_OFFBIG] = sizeof(long)==4 ? 1 : -1,
		[_SC_XBS5_LP64_OFF64] = sizeof(long)==8 ? 1 : -1,
		[_SC_XBS5_LPBIG_OFFBIG] = -1,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_XOPEN_LEGACY] = _XOPEN_LEGACY,
		[_SC_XOPEN_REALTIME] = _XOPEN_REALTIME,
		[_SC_XOPEN_REALTIME_THREADS] = _XOPEN_REALTIME_THREADS,
		[_SC_ADVISORY_INFO] = _POSIX_ADVISORY_INFO,
		[_SC_BARRIERS] = _POSIX_BARRIERS,
		[_SC_CLOCK_SELECTION] = _POSIX_CLOCK_SELECTION,
		[_SC_CPUTIME] = _POSIX_CPUTIME,
		[_SC_THREAD_CPUTIME] = _POSIX_THREAD_CPUTIME,
		[_SC_MONOTONIC_CLOCK] = _POSIX_MONOTONIC_CLOCK,
		[_SC_READER_WRITER_LOCKS] = _POSIX_READER_WRITER_LOCKS,
		[_SC_SPIN_LOCKS] = _POSIX_SPIN_LOCKS,
		[_SC_REGEXP] = _POSIX_REGEXP,
		[_SC_SHELL] = _POSIX_SHELL,
		[_SC_SPAWN] = _POSIX_SPAWN,
		[_SC_SPORADIC_SERVER] = _POSIX_SPORADIC_SERVER,
		[_SC_THREAD_SPORADIC_SERVER] = _POSIX_THREAD_SPORADIC_SERVER,
		[_SC_TIMEOUTS] = _POSIX_TIMEOUTS,
		[_SC_TYPED_MEMORY_OBJECTS] = _POSIX_TYPED_MEMORY_OBJECTS,
		[_SC_2_PBS] = _POSIX2_PBS,
		[_SC_2_PBS_ACCOUNTING] = _POSIX2_PBS,
		[_SC_2_PBS_LOCATE] = _POSIX2_PBS,
		[_SC_2_PBS_MESSAGE] = _POSIX2_PBS,
		[_SC_2_PBS_TRACK] = _POSIX2_PBS,
#elif defined(__linux__)
		[_SC_XOPEN_LEGACY] = -1,
		[_SC_XOPEN_REALTIME] = -1,
		[_SC_XOPEN_REALTIME_THREADS] = -1,
		[_SC_ADVISORY_INFO] = VER,
		[_SC_BARRIERS] = VER,
		[_SC_CLOCK_SELECTION] = VER,
		[_SC_CPUTIME] = VER,
		[_SC_THREAD_CPUTIME] = VER,
		[_SC_MONOTONIC_CLOCK] = VER,
		[_SC_READER_WRITER_LOCKS] = VER,
		[_SC_SPIN_LOCKS] = VER,
		[_SC_REGEXP] = 1,
		[_SC_SHELL] = 1,
		[_SC_SPAWN] = VER,
		[_SC_SPORADIC_SERVER] = -1,
		[_SC_THREAD_SPORADIC_SERVER] = -1,
		[_SC_TIMEOUTS] = VER,
		[_SC_TYPED_MEMORY_OBJECTS] = -1,
		[_SC_2_PBS] = -1,
		[_SC_2_PBS_ACCOUNTING] = -1,
		[_SC_2_PBS_LOCATE] = -1,
		[_SC_2_PBS_MESSAGE] = -1,
		[_SC_2_PBS_TRACK] = -1,
#endif
		[_SC_SYMLOOP_MAX] = SYMLOOP_MAX,
#if defined(__linux__)
		[_SC_STREAMS] = JT_ZERO,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_2_PBS_CHECKPOINT] = _POSIX2_PBS,
		[_SC_V6_ILP32_OFF32] = _POSIX_V6_ILP32_OFF32,
		[_SC_V6_ILP32_OFFBIG] = (_POSIX_V6_ILP32_OFFBIG == 0) ? _VAL_V6_ILP32 : _POSIX_V6_ILP32_OFFBIG,
		[_SC_V6_LP64_OFF64] = (_POSIX_V6_LP64_OFF64 == 0) ? _VAL_V6_LP64 : _POSIX_V6_LP64_OFF64,
		[_SC_V6_LPBIG_OFFBIG] = (_POSIX_V6_LPBIG_OFFBIG == 0) ? _VAL_V6_LPBIG : _POSIX_V6_LPBIG_OFFBIG,
#elif defined(__linux__)
		[_SC_2_PBS_CHECKPOINT] = -1,
		[_SC_V6_ILP32_OFF32] = -1,
		[_SC_V6_ILP32_OFFBIG] = sizeof(long)==4 ? 1 : -1,
		[_SC_V6_LP64_OFF64] = sizeof(long)==8 ? 1 : -1,
		[_SC_V6_LPBIG_OFFBIG] = -1,
#endif
		[_SC_HOST_NAME_MAX] = HOST_NAME_MAX,
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_TRACE] = _POSIX_TRACE,
		[_SC_TRACE_EVENT_FILTER] = _POSIX_TRACE,
		[_SC_TRACE_INHERIT] = _POSIX_TRACE,
		[_SC_TRACE_LOG] = _POSIX_TRACE,
#elif defined(__linux__)
		[_SC_TRACE] = -1,
		[_SC_TRACE_EVENT_FILTER] = -1,
		[_SC_TRACE_INHERIT] = -1,
		[_SC_TRACE_LOG] = -1,
#endif

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_IPV6] = __ipv6_sysconf(),
		[_SC_RAW_SOCKETS] = _POSIX_RAW_SOCKETS,
		[_SC_V7_ILP32_OFF32] = _POSIX_V7_ILP32_OFF32,
		[_SC_V7_ILP32_OFFBIG] = (_POSIX_V7_ILP32_OFFBIG == 0) ? _VAL_V7_ILP32 : _POSIX_V7_ILP32_OFFBIG,
		[_SC_V7_LP64_OFF64] = (_POSIX_V7_LP64_OFF64 == 0) ? _VAL_V7_LP64 : _POSIX_V7_LP64_OFF64,
		[_SC_V7_LPBIG_OFFBIG] = (_POSIX_V7_LPBIG_OFFBIG == 0) ? _VAL_V7_LPBIG : _POSIX_V7_LPBIG_OFFBIG,
#elif defined(__linux__)
		[_SC_IPV6] = VER,
		[_SC_RAW_SOCKETS] = VER,
		[_SC_V7_ILP32_OFF32] = -1,
		[_SC_V7_ILP32_OFFBIG] = sizeof(long)==4 ? 1 : -1,
		[_SC_V7_LP64_OFF64] = sizeof(long)==8 ? 1 : -1,
		[_SC_V7_LPBIG_OFFBIG] = -1,
#endif
#if defined(__linux__)
		[_SC_SS_REPL_MAX] = -1,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_TRACE_EVENT_NAME_MAX] = _POSIX_TRACE,
#elif defined(__linux__)
		[_SC_TRACE_EVENT_NAME_MAX] = -1,
#endif
#if defined(__linux__)
		[_SC_TRACE_NAME_MAX] = -1,
		[_SC_TRACE_SYS_MAX] = -1,
		[_SC_TRACE_USER_EVENT_MAX] = -1,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_XOPEN_STREAMS] = _XOPEN_STREAMS,
		[_SC_THREAD_ROBUST_PRIO_INHERIT] = _POSIX_THREAD_ROBUST_PRIO_INHERIT,
		[_SC_THREAD_ROBUST_PRIO_PROTECT] = _POSIX_THREAD_ROBUST_PRIO_PROTECT,
#elif defined(__linux__)
		[_SC_XOPEN_STREAMS] = JT_ZERO,
		[_SC_THREAD_ROBUST_PRIO_INHERIT] = -1,
		[_SC_THREAD_ROBUST_PRIO_PROTECT] = -1,
#endif
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		[_SC_XOPEN_UUCP] = _XOPEN_UUCP,
#endif

#if defined(__linux__)
		[_SC_MINSIGSTKSZ] = JT_MINSIGSTKSZ,
		[_SC_SIGSTKSZ] = JT_SIGSTKSZ,
#endif
	};

	if (name >= sizeof(values)/sizeof(values[0]) || !values[name]) {
		errno = EINVAL;
		return -1;
	} else if (values[name] >= -1) {
		return values[name];
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	}
#elif defined(__linux__)
	} else if (values[name] < -256) {
		struct rlimit lim;
		getrlimit(values[name]&16383, &lim);
		if (lim.rlim_cur == RLIM_INFINITY)
			return -1;
		return lim.rlim_cur > LONG_MAX ? LONG_MAX : lim.rlim_cur;
	}

	switch ((unsigned char)values[name]) {
	case VER & 255:
		return _POSIX_VERSION;
	case JT_ARG_MAX & 255:
		return ARG_MAX;
	case JT_MQ_PRIO_MAX & 255:
		return MQ_PRIO_MAX;
	case JT_PAGE_SIZE & 255:
		return PAGE_SIZE;
	case JT_SEM_VALUE_MAX & 255:
		return SEM_VALUE_MAX;
	case JT_DELAYTIMER_MAX & 255:
		return DELAYTIMER_MAX;
	case JT_NPROCESSORS_CONF & 255:
	case JT_NPROCESSORS_ONLN & 255: ;
		unsigned char set[128] = {1};
		int i, cnt;
		__syscall(SYS_sched_getaffinity, 0, sizeof set, set);
		for (i=cnt=0; i<sizeof set; i++)
			for (; set[i]; set[i]&=set[i]-1, cnt++);
		return cnt;
	case JT_PHYS_PAGES & 255:
	case JT_AVPHYS_PAGES & 255: ;
		unsigned long long mem;
		struct sysinfo si;
		__lsysinfo(&si);
		if (!si.mem_unit) si.mem_unit = 1;
		if (name==_SC_PHYS_PAGES) mem = si.totalram;
		else mem = si.freeram + si.bufferram;
		mem *= si.mem_unit;
		mem /= PAGE_SIZE;
		return (mem > LONG_MAX) ? LONG_MAX : mem;
	case JT_MINSIGSTKSZ & 255:
	case JT_SIGSTKSZ & 255: ;
		/* Value from auxv/kernel is only sigfame size. Clamp it
		 * to at least 1k below arch's traditional MINSIGSTKSZ,
		 * then add 1k of working space for signal handler. */
		unsigned long sigframe_sz = __getauxval(AT_MINSIGSTKSZ);
		if (sigframe_sz < MINSIGSTKSZ - 1024)
			sigframe_sz = MINSIGSTKSZ - 1024;
		unsigned val = sigframe_sz + 1024;
		if (values[name] == JT_SIGSTKSZ)
			val += SIGSTKSZ - MINSIGSTKSZ;
		return val;
	case JT_ZERO & 255:
		return 0;
	}
#endif
	return values[name];
}
