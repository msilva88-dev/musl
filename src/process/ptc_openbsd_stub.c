/* Minimal stubs for fork/posix_spawn helpers (single-thread stage). */
#include <signal.h>
#include <stddef.h>

/* Prevent “pthread cancellation” type interference around fork; no-op here. */
void __inhibit_ptc(void) {}
void __release_ptc(void) {}

/* Block app signals around fork/exec; for stage-2 we no-op safely. */
void __block_app_sigs(sigset_t *set)
{
	/* Provide a defined value for later restore calls. */
	if (set) sigemptyset(set);
}

void __restore_sigs(const sigset_t *set)
{
	(void)set;
}

/* Used by setxid/wordexp paths; return 0 = “nothing blocked”. */
void __block_all_sigs(sigset_t *set)
{
	if (set) sigemptyset(set);
}
