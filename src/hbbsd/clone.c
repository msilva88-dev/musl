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

/* musl prototype uses varargs to carry ptid/tls/ctid when present */
int __clone(int (*fn)(void *), void *stack, int flags, void *arg, ...)
{
	// struct start_args *, int *, struct pthread *+, volatile int *
	// args, &new->tid, TP_ADJ(new), &__thread_list_lock
	/* swallow optional variadic arguments (ptid, tls, ctid) */
	va_list ap;
	va_start(ap, arg);
	if (flags & CLONE_SETTLS | CLONE_THREAD) {
		args = va_arg(ap, struct start_args *);
	}
	if (flags & (CLONE_PARENT_SETTID | CLONE_CHILD_SETTID)) {
		ptid = va_arg(ap, int *);
	}
	if (flags & CLONE_SETTLS | CLONE_THREAD) {
		pth = va_arg(ap, void *);
	}
	if (flags & CLONE_SIGHAND | CLONE_THREAD) {
		_thread_lock = va_arg(ap, int *);
	}
	va_end(ap);

	/* If CLONE_VM or thread flags are requested, use pthread */
	if (flags & CLONE_VM) {
		struct stack {
			struct stack *link; /* link for free default stacks */
			void *sp; /* machine stack pointer */
			void *base; /* bottom of allocated area */
			size_t guardsize; /* size of PROT_NONE zone or */
				/* ==1 if application alloced */
			size_t len; /* total size of allocated stack */
		};

		struct bsd_pthread {
			//struct __sem donesem; // <- sem <- _SPINLOCK_UNLOCKED
			unsigned int flags;
			//_atomic_lock_t flags_lock; <- _SPINLOCK_UNLOCKED
			struct tib *tib;
			void *retval;
			void *(*fn)(void *);
			void *arg;
			char name[32];
			struct stack *stack;
			//LIST_ENTRY(pthread) threads;
			//TAILQ_ENTRY(pthread) waiting;
			//pthread_cond_t blocking_cond;
			//struct pthread_attr attr;
			//struct rthread_storage *local_storage;
			//struct rthread_cleanup_fn *cleanup_fns;

			/* cancel received in a delayed cancel block? */
			int delayed_cancel;
		};

		struct tib {
#if defined(__i386) || defined(__amd64)
			struct tib *__tib_self;
#define __tib_tcb __tib_self
#endif
			void *tib_dtv; /* internal to the runtime linker */
			void *tib_thread;
			void *tib_locale;
			int tib_errno;
			int tib_canceled;
			int tib_cancel_point;
			int tib_cantcancel;
			pid_t tib_tid;
			int tib_thread_flags; /* internal to libpthread */
			void *tib_atexit;
		} *bsd_tib = __init_tls(sizeof(struct bsd_pthread));

		if (bsd_tib == NULL) {
			return ENOMEM;
		}

		bsd_tib->tib_tid = -1;

		struct stack bsd_stack = {
			NULL,
			pth->stack, // void *stack -> void *sp
			pth->map_base, // unsigned char *map_base -> void *base
			pth->guard_size, // size_t guard_size -> size_t guardsize
			pth->stack_size // size_t stack_size -> size_t len
		};

		struct __tfork {
			void *tf_tcb; // Thread control block (TLS base)
			void *tf_stack; // Stack pointer
			void *tf_func; // Initial function
			void *tf_arg; // Argument
			void *tf_tid; // Thread ID
		} param = {
			TP_ADJ(bsd_tib),
			&bsd_stack,
			args->start_func,
			args->start_arg,
			&bsd_tib->tib_tid // ptid or &pth->tid
		};

		pid_t ret = syscall(SYS___tfork, &param, sizeof(param));

		if (ret != 0 || ret == -1) {
			return ret;
		}

		fn(args);

		syscall(SYS___threxit, 0);
	}

	/* If there are no thread flags, use fork() */
	pid_t pid = fork();

	if (pid < 0) {
		return -1;
	} else if (pid == 0) {
		/* child: execute the function */
		int ret = fn(arg);
		_exit(ret);
	}

	/* parent: return the child's PID */
	return pid;
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
