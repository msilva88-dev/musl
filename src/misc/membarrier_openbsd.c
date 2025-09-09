/* Single-process barrier used by dynlink; emulate with a compiler fence. */
#if defined(__GNUC__)
#  define fence() __atomic_thread_fence(__ATOMIC_SEQ_CST)
#else
static inline void fence(void) { /* best-effort */ }
#endif

int __membarrier(void)
{
	fence();
	return 0;
}
