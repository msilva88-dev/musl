/* Minimal PTC hooks for single-thread stage. */

/* Prevent “pthread cancellation” type interference around fork; no-op here. */
void __inhibit_ptc(void) {}
void __release_ptc(void) {}

/* Note:
 * __block_app_sigs/__restore_sigs/__block_all_sigs live in
 * src/misc/sig_openbsd_stubs.c for stage-2. We intentionally
 * do not duplicate them here to avoid multiple-definition errors.
 */
