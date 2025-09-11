#ifndef OPENBSD_X86_64_RELOC_H
#define OPENBSD_X86_64_RELOC_H

#include <elf.h>

/* Dynamic linker arch tag */
#define LDSO_ARCH "x86_64"

/* Common x86_64 relocations */
#define REL_SYMBOLIC    R_X86_64_64
#define REL_OFFSET32    R_X86_64_PC32
#define REL_GOT         R_X86_64_GLOB_DAT
#define REL_PLT         R_X86_64_JUMP_SLOT
#define REL_RELATIVE    R_X86_64_RELATIVE
#define REL_COPY        R_X86_64_COPY

/* --- TLS relocations on OpenBSD/amd64 ---
 * Use the 32-bit forms for TP/DTP offsets.
 */
#undef  REL_DTPMOD
#undef  REL_DTPOFF
#undef  REL_TPOFF
#undef  REL_TLSDESC
#define REL_DTPMOD      R_X86_64_DTPMOD64
#define REL_DTPOFF      R_X86_64_DTPOFF32
#define REL_TPOFF       R_X86_64_TPOFF32
#define REL_TLSDESC     R_X86_64_TLSDESC

/* x86_64 uses forward TLSDESC layout */
#define TLSDESC_BACKWARDS 0

/* Jump helper used by the loader */
#define CRTJMP(pc,sp) __asm__ __volatile__( \
    "mov %1,%%rsp ; jmp *%0" : : "r"(pc), "r"(sp) : "memory" )

/* Resolve symbol addresses from within ldso itself */
#define GETFUNCSYM(fp, sym, got) __asm__ ( \
    ".hidden " #sym "\n" \
    "    lea " #sym "(%%rip),%0\n" \
    : "=r"(*fp) : : "memory" )

#endif /* OPENBSD_X86_64_RELOC_H */
