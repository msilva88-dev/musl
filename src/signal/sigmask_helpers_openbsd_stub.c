#include <signal.h>
#include <errno.h>

/* These helpers are referenced by fork/posix_spawn code paths.
 * For stage-2 single-thread bootstrap we provide neutral behavior.
 */

int __block_app_sigs(sigset_t *set);
void __restore_sigs(const sigset_t *set);
int __block_all_sigs(sigset_t *set);

/* Provide weak aliases so multiple CUs can include their declarations safely. */
#if defined(__GNUC__)
__attribute__((weak, alias("__block_app_sigs")))
int __block_app_sigs_weak(sigset_t *);
__attribute__((weak, alias("__restore_sigs")))
void __restore_sigs_weak(const sigset_t *);
__attribute__((weak, alias("__block_all_sigs")))
int __block_all_sigs_weak(sigset_t *);
#endif
