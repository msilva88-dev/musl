/* OpenBSD overlay for x86_64 relocations.
 * Reuse upstream x86_64 definitions, then patch any missing bits.
 */
#ifndef OBSD_X86_64_RELOC_H
#define OBSD_X86_64_RELOC_H

#if defined(__has_include_next)
# include_next "reloc.h"
#else
/* Fallback: rely on include path ordering to pick arch/x86_64/reloc.h */
# include "reloc.h"
#endif

/* x86_64 uses TP at the TCB; no bias. */
#ifndef TPOFF_K
#define TPOFF_K 0
#endif

/* Also ensure GAP_ABOVE_TP is available when dynlink includes only reloc.h. */
#ifndef GAP_ABOVE_TP
#define GAP_ABOVE_TP 0
#endif

#endif /* OBSD_X86_64_RELOC_H */
