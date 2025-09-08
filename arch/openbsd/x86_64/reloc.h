/* OpenBSD overlay for x86_64 relocations.
 * Reuse the upstream x86_64 definitions, then patch any missing bits.
 */
#if defined(__has_include_next)
#  include_next "reloc.h"
#else
/* Fallback: rely on include path ordering to pick arch/x86_64/reloc.h */
#  include "reloc.h"
#endif

/* x86_64 uses TP at the TCB; no bias. */
#ifndef TPOFF_K
#define TPOFF_K 0
#endif
