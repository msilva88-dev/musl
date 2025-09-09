/* Minimal stubs for fork/posix_spawn helpers (single-thread stage). */
#include <stddef.h>
#include <signal.h> /* for sigemptyset/sigset_t used internally */

/* Prevent “pthread cancellation” type interference around fork; no-op here. */
void __inhibit_ptc(void) {}
void __release_ptc(void) {}

/* Block app signals around fork/exec; stage-2 no-op.
 * The interface uses void* in musl; if a buffer is provided, clear it.
 */
void __block_app_sigs(void *set)
{
	if (set) sigemptyset((sigset_t *)set);
}

void __restore_sigs(void *set)
{
	(void)set;
}

/* Used by setxid/wordexp paths; return 0 = “nothing blocked”. */
void __block_all_sigs(void *set)
{
	if (set) sigemptyset((sigset_t *)set);
}
