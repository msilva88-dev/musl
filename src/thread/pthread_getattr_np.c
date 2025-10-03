#define _GNU_SOURCE
#include "pthread_impl.h"
#include "libc.h"
#include <sys/mman.h>

int pthread_getattr_np(pthread_t t, pthread_attr_t *a)
{
	*a = (pthread_attr_t){0};
	a->_a_detach = t->detach_state>=DT_DETACHED;
	a->_a_guardsize = t->guard_size;
	if (t->stack) {
		a->_a_stackaddr = (uintptr_t)t->stack;
		a->_a_stacksize = t->stack_size;
	} else {
		char *p = (void *)libc.auxv;
		size_t l = PAGE_SIZE;
		p += -(uintptr_t)p & PAGE_SIZE-1;
		a->_a_stackaddr = (uintptr_t)p;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
		while (1) {
			void *adj = mmap(
				p-l-PAGE_SIZE,
				2*PAGE_SIZE,
				PROT_READ | PROT_WRITE,
				MAP_ANON | MAP_PRIVATE | MAP_FIXED,
				-1,
				0
			);

			if (adj == MAP_FAILED && errno == ENOMEM) {
				l += PAGE_SIZE;
			} else {
				break;
			}
		}
#elif defined(__linux__)
		while (mremap(p-l-PAGE_SIZE, PAGE_SIZE, 2*PAGE_SIZE, 0)==MAP_FAILED && errno==ENOMEM)
			l += PAGE_SIZE;
#endif
		a->_a_stacksize = l;
	}
	return 0;
}
