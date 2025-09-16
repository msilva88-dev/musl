#define _GNU_SOURCE
#include <stdarg.h>
#include <unistd.h>
#include <sched.h>
#include "pthread_impl.h"
#include "syscall.h"
#include "lock.h"
#include "fork_impl.h"

struct clone_start_args {
	int (*func)(void *);
	void *arg;
	sigset_t sigmask;
};

static int clone_start(void *arg)
{
	struct clone_start_args *csa = arg;
	__post_Fork(0);
	__restore_sigs(&csa->sigmask);
	return csa->func(csa->arg);
}

int __clone(int (*fn)(void *), void *stack, int flags, void *arg, ...)
{
	if (!fn || !stack) {
		return -EINVAL;
	}

	va_list ap;
#if defined(__i386__) \
	|| defined(__powerpc64__) \
	|| (defined(__riscv) && (__riscv_xlen == 64))
	uintptr_t sp = ((uintptr_t)stack & ~0xF) - 16;
#elif defined(__s390x__)
	uintptr_t sp = ((uintptr_t)stack & ~0xF) - 160;
#elif defined(__x86_64__)
	uintptr_t sp = ((uintptr_t)stack & ~0xF) - 8;
#else
	uintptr_t sp = ((uintptr_t)stack & ~0xF);
#endif
	struct start_args *args = NULL;
	pid_t *ctid = NULL __attribute__((unused)),
	pid_t pid = -1, *ptid = NULL, ptid_def = -1;
	int ret = 0;
	void *shmem = NULL;
	struct pthread *tls = NULL;

	va_start(ap, arg);

	args = va_arg(ap, struct start_args *);
	if (!args) {
		return -EINVAL;
	}

#if defined(__i386__) || defined(__x86_64__)
	((void **)sp)[0] = args;
#elif defined(__s390x__)
	((void **)sp)[1] = fn;
	((void **)sp)[2] = args;
#else
	((void **)sp)[0] = fn;
	((void **)sp)[1] = args;
#endif
#if defined(__loongarch__) && defined(__loongarch64)
	sp -= 16;
#endif

	if (flags & CLONE_THREAD) {
		if (flags & CLONE_PARENT_SETTID) {
			ptid = va_arg(ap, pid_t *);
			if (!ptid) {
				return -EINVAL;
			}
		}

		if (flags & CLONE_SETTLS) {
			tls = va_arg(ap, struct pthread *);
			if (!tls) {
				return -EINVAL;
			}
		}

		if (flags & CLONE_CHILD_SETTID) {
			ctid = va_arg(ap, pid_t *);
			if (!ctid) {
				return -EINVAL;
			}
		}
	}

	va_end(ap);

	/* If CLONE_VM and thread flags are requested, use pthread */
	if ((flags & CLONE_THREAD) && (flags & CLONE_VM)) {
#if defined(__aarch64__) \
        || defined(__i386__) \
        || (defined(__loongarch__) && defined(__loongarch64)) \
        || defined(__powerpc64__) \
        || (defined(__riscv) && (__riscv_xlen == 64)) \
        || defined(__s390x__) \
        || defined(__x86_64__)
#define _atomic_lock_t int
#else
#define _atomic_lock_t unsigned char
#endif

		// This structures is required by bsd_tib pointer
		struct bsd_pthread_unused {
			struct { // __sem
				_atomic_lock_t lock;
				// waitcount and value
				volatile int wc_v[2];
				int shared;
			} donesem;
			unsigned int flags;
			_atomic_lock_t flags_lock;
			struct tib *tib;
			void *retval;
			void *(*fn)(void *);
			void *arg;
			char name[32];
			struct stack *stack;
			struct { // LIST ENTRY
				struct bsd_pthread_padd *le_next;
				struct bsd_pthread_padd **le_prev;
			} threads;
			struct { // TAILQ ENTRY
				struct bsd_pthread_padd *tqe_next;
				struct bsd_pthread_padd **tqe_prev;
			} waiting;
			void *blocking_cond; // pthread_cond *
			struct { // pthread_attr
				void *stack_addr;
				// stack_size and guard_size
				size_t ss_gs[2];
				// detach_state, contention_scope, sched_policy
				int st_cs_sp[3];
				struct { // sched_param
					int sched_priority;
				} sched_param;
				int sched_inherit;
			} attr;
			void *local_storage; // struct rthread_storage *
			void *cleanup_fns; // struct rthread_cleanup_fn *
			int delayed_cancel;
		};

		struct stack {
			struct stack *link; // Link for free default stacks
			void *sp; //Machine stack pointer
			void *base; // Bottom of allocated area
			/*
			 * Size of PROT_NONE zone or
			 * one if application allocated.
			 */
			size_t guardsize;
			size_t len; // Total size of allocated stack
		} bsd_stack = { NULL, NULL, NULL, 0, 0 };

		struct tib {
#if defined(__i386__) || defined(__x86_64__)
			struct tib *__tib_self;
#endif
			void *tib_dtv; // Internal to the runtime linker
			void *tib_thread; // Unused
			void *tib_locale;
			int tib_errno;
			int tib_canceled;
			int tib_cancel_point;
			int tib_cantcancel;
			pid_t tib_tid;
			int tib_thread_flags; // Internal to libpthread
			void *tib_atexit;
		} *bsd_tib = NULL;

		struct __tfork {
			void *tf_tcb; // Thread control block (TLS base)
			void *tf_stack; // Stack pointer
			void *tf_func; // Initial function
			void *tf_arg; // Argument
			void *tf_tid; // Thread ID
		} param = { NULL, NULL, NULL, NULL, NULL };

		if (flags & CLONE_SETTLS) {
			bsd_tib = __init_tls(sizeof(struct bsd_pthread_padd));

			if (bsd_tib == NULL) {
				return ENOMEM;
			}

			if (ptid && (flags & CLONE_PARENT_SETTID)) {
				bsd_tib->tib_tid = *ptid;
			} else {
				bsd_tib->tib_tid = ptid_def;
			}

			bsd_stack.sp = (void *)sp; // uintptr_t -> void *
			bsd_stack.base = tls->map_base; // uchar_t * -> void *
			bsd_stack.guardsize = tls->guard_size; // size_t
			bsd_stack.len = tls->stack_size; // size_t

			// Thread control block (TLS base)
			param.tf_tcb = TP_ADJ(bsd_tib);
			// Stack pointer
			param.tf_stack = bsd_stack.sp;
			// Start function
			param.tf_func = args->start_func;
			// Start argument
			param.tf_arg = args->start_arg;
			// Thread ID
			param.tf_tid = &bsd_tib->tib_tid;
		} else {
			bsd_stack.sp = (void *)sp; // uintptr_t -> void *

			// Stack pointer
			param.tf_stack = bsd_stack.sp;
			// Start function
			param.tf_func = args->start_func;
			// Start argument
			param.tf_arg = args->start_arg;

			if (ptid && (flags & CLONE_PARENT_SETTID)) {
				param.tf_tid = &ptid;
			} else {
				param.tf_tid = &ptid_def;
			}
		}

		pid = syscall(SYS___tfork, &param, sizeof(param));
	/* If CLONE_VM without thread flags are requested */
	} else if ((flags & CLONE_VM) && (flags & CLONE_VFORK)) {
		shmem = mmap(
			NULL,
			sizeof(char[1024+PATH_MAX]),
			PROT_READ | PROT_WRITE,
			MAP_ANON | MAP_SHARED,
			-1,
			0
		);

	        if (shmem == MAP_FAILED) {
	            return -ENOMEM;
	        }

	        stack = shmem;
	}

	struct sigaction sanew = {
		0,
		.sa_handler = SIG_DFL,
		.sa_flags = SA_NOCLDWAIT
	}, saold = { 0 };

        /* If there are no thread flags, use fork() */
	if (!(flags & CLONE_THREAD)) {
		if (!(flags & SIGCHLD)) {
			sigaction(SIGCHLD, &sanew, &saold);
		}

		if (flags & CLONE_VFORK) {
			pid = vfork();
		} else {
			pid = fork();
		}
	}

	// syscall or fork failed, propagate error
	if (pid != 0) {
		if (
			shmem
			&& (flags & CLONE_VM)
			&& (flags & CLONE_VFORK)
			&& !(flags & CLONE_THREAD)
		) {
			munmap(shmem, sizeof(char[1024+PATH_MAX]));
		}

		if (!(flags & SIGCHLD)) {
			sigaction(SIGCHLD, &saold, NULL);
		}

		// pid non-zero is always non-zero
		// pid -1 is always -1
		/* parent: return the child's PID */
		return pid;
	}

	/* child: execute the function */
#if defined(__i386__) || defined(__x86_64__)
	void *child_arg = ((void **)sp)[1];

	ret = fn(child_arg);
#elif defined(__s390x__)
	int (*child_fn)(void *) = ((int (*)(void *))((void **)sp)[1]);
	void *child_arg = ((void **)sp)[2];

	ret = child_fn(child_arg);
#else
	int (*child_fn)(void *) = ((int (*)(void *))((void **)sp)[0]);
	void *child_arg = ((void **)sp)[1];

	ret = child_fn(child_arg);
#endif

	if ((flags & CLONE_THREAD) && (flags & CLONE_VM)) {
		if (
			ctid
			&& (flags & CLONE_CHILD_CLEARTID)
			&& (flags & CLONE_CHILD_SETTID)
		) {
			*ctid = 0;
			futex(ctid, FUTEX_WAKE, 1, NULL, NULL, 0);
		}

		syscall(SYS___threxit, ret);
	} else {
		if (!(flags & SIGCHLD)) {
			sigaction(SIGCHLD, &saold, NULL);
		}

		_exit(ret);
	}

	__builtin_unreachable();
}

int clone(int (*func)(void *), void *stack, int flags, void *arg, ...)
{
	struct clone_start_args csa;
	va_list ap;
	pid_t *ptid = 0, *ctid = 0;
	void  *tls = 0;

	/* Flags that produce an invalid thread/TLS state are disallowed. */
	int badflags = CLONE_THREAD | CLONE_SETTLS | CLONE_CHILD_CLEARTID;

	if ((flags & badflags) || !stack)
		return __syscall_ret(-EINVAL);

	va_start(ap, arg);
	if (flags & (CLONE_PIDFD | CLONE_PARENT_SETTID | CLONE_CHILD_SETTID))
	 	ptid = va_arg(ap, pid_t *);
	if (flags & CLONE_CHILD_SETTID) {
		tls = va_arg(ap, void *);
		ctid = va_arg(ap, pid_t *);
	}
	va_end(ap);

	/* If CLONE_VM is used, it's impossible to give the child a consistent
	 * thread structure. In this case, the best we can do is assume the
	 * caller is content with an extremely restrictive execution context
	 * like the one vfork() would provide. */
	if (flags & CLONE_VM) return __syscall_ret(
		__clone(func, stack, flags, arg, ptid, tls, ctid));

	__block_all_sigs(&csa.sigmask);
	LOCK(__abort_lock);

	/* Setup the a wrapper start function for the child process to do
	 * mimic _Fork in producing a consistent execution state. */
	csa.func = func;
	csa.arg = arg;
	int ret = __clone(clone_start, stack, flags, &csa, ptid, tls, ctid);

	__post_Fork(ret);
	__restore_sigs(&csa.sigmask);
	return __syscall_ret(ret);
}
