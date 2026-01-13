/*
 * Copyright (c) 1989, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* nlist from OpenBSD 7.0 source code: lib/libc/gen/nlist.c */

#define _BSD_SOURCE
#include <sys/mman.h>
#include <sys/stat.h>
#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <nlist.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#if ULONG_MAX == 0xffffffff
#define Elf_Ehdr Elf64_Ehdr
#define Elf_Off Elf64_Off
#define Elf_Shdr Elf64_Shdr
#define ELF_ST_BIND ELF64_ST_BIND
#define ELF_ST_TYPE ELF64_ST_TYPE
#define Elf_Sword Elf64_Sword
#define Elf_Sym Elf64_Sym
#define Elf_Word Elf64_Word
#else
#define Elf_Ehdr Elf32_Ehdr
#define Elf_Off Elf32_Off
#define Elf_Shdr Elf32_Shdr
#define ELF_ST_BIND ELF32_ST_BIND
#define ELF_ST_TYPE ELF32_ST_TYPE
#define Elf_Sword Elf32_Sword
#define Elf_Sym Elf32_Sym
#define Elf_Word Elf32_Word
#endif

#define MINIMUM(a, b) (((a) < (b)) ? (a) : (b))
#define ISLAST(p) (p->n_name == 0 || p->n_name[0] == 0)

/*
 * __elf_is_okay__ - Determine if ehdr really
 * is ELF and valid for the target platform.
 *
 * WARNING:  This is NOT a ELF ABI function and
 * as such its use should be restricted.
 */
static int __elf_is_okay__(Elf_Ehdr *ehdr)
{
	int retval = 0;
	/*
	 * We need to check magic, class size, endianess,
	 * and version before we look at the rest of the
	 * Elf_Ehdr structure.  These few elements are
	 * represented in a machine independent fashion.
	 */
	if (ehdr->e_ident[EI_MAG0] == ELFMAG0 &&
	    ehdr->e_ident[EI_MAG1] == ELFMAG1 &&
	    ehdr->e_ident[EI_MAG2] == ELFMAG2 &&
	    ehdr->e_ident[EI_MAG3] == ELFMAG3 &&
	    ehdr->e_ident[EI_CLASS] == ELF_TARG_CLASS &&
	    ehdr->e_ident[EI_DATA] == ELF_TARG_DATA &&
	    ehdr->e_ident[EI_VERSION] == ELF_TARG_VER) {

		/* Now check the machine dependent header */
		if (ehdr->e_machine == ELF_TARG_MACH &&
		    ehdr->e_version == ELF_TARG_VER)
			retval = 1;
	}

	if (ehdr->e_shentsize != sizeof(Elf_Shdr))
		return 0;

	return retval;
}

static int __fdnlist(int fd, struct nlist *list)
{
	struct nlist *p;
	caddr_t strtab;
	Elf_Off symoff = 0, symstroff = 0;
	Elf_Word symsize = 0, symstrsize = 0;
	Elf_Sword nent, cc, i;
	Elf_Sym sbuf[1024];
	Elf_Sym *s;
	Elf_Ehdr ehdr;
	Elf_Shdr *shdr = NULL;
	Elf_Word shdr_size;
	struct stat st;
	int usemalloc = 0;
	size_t left, len;

	/* Make sure obj is OK */
	if (pread(fd, &ehdr, sizeof(Elf_Ehdr), 0) != sizeof(Elf_Ehdr) ||
	    !__elf_is_okay__(&ehdr) || fstat(fd, &st) == -1)
		return -1;

	/* calculate section header table size */
	shdr_size = ehdr.e_shentsize * ehdr.e_shnum;

	/* Make sure it's not too big to mmap */
	if (SIZE_MAX - ehdr.e_shoff < shdr_size ||
	    (S_ISREG(st.st_mode) && ehdr.e_shoff + shdr_size > st.st_size)) {
		errno = EFBIG;
		return -1;
	}

	/* mmap section header table */
	shdr = mmap(NULL, shdr_size, PROT_READ, MAP_SHARED|MAP_FILE, fd,
	    ehdr.e_shoff);
	if (shdr == MAP_FAILED) {
		usemalloc = 1;
		if ((shdr = malloc(shdr_size)) == NULL)
			return -1;

		if (pread(fd, shdr, shdr_size, ehdr.e_shoff) != shdr_size) {
			free(shdr);
			return -1;
		}
	}

	/*
	 * Find the symbol table entry and its corresponding
	 * string table entry.	Version 1.1 of the ABI states
	 * that there is only one symbol table but that this
	 * could change in the future.
	 */
	for (i = 0; i < ehdr.e_shnum; i++) {
		if (shdr[i].sh_type == SHT_SYMTAB) {
			if (shdr[i].sh_link >= ehdr.e_shnum)
				continue;
			symoff = shdr[i].sh_offset;
			symsize = shdr[i].sh_size;
			symstroff = shdr[shdr[i].sh_link].sh_offset;
			symstrsize = shdr[shdr[i].sh_link].sh_size;
			break;
		}
	}

	/* Flush the section header table */
	if (usemalloc)
		free(shdr);
	else
		munmap((caddr_t)shdr, shdr_size);

	/*
	 * clean out any left-over information for all valid entries.
	 * Type and value defined to be 0 if not found; historical
	 * versions cleared other and desc as well.  Also figure out
	 * the largest string length so don't read any more of the
	 * string table than we have to.
	 *
	 * XXX clearing anything other than n_type and n_value violates
	 * the semantics given in the man page.
	 */
	nent = 0;
	for (p = list; !ISLAST(p); ++p) {
		p->n_type = 0;
		p->n_other = 0;
		p->n_desc = 0;
		p->n_value = 0;
		++nent;
	}

	/* Don't process any further if object is stripped. */
	/* ELFism - dunno if stripped by looking at header */
	if (symoff == 0)
		return nent;

	/* Check for files too large to mmap. */
	if (SIZE_MAX - symstrsize < symstroff ||
	    (S_ISREG(st.st_mode) && symstrsize + symstroff > st.st_size)) {
		errno = EFBIG;
		return -1;
	}

	/*
	 * Map string table into our address space.  This gives us
	 * an easy way to randomly access all the strings, without
	 * making the memory allocation permanent as with malloc/free
	 * (i.e., munmap will return it to the system).
	 */
	if (usemalloc) {
		if ((strtab = malloc(symstrsize)) == NULL)
			return -1;
		if (pread(fd, strtab, symstrsize, symstroff) != symstrsize) {
			free(strtab);
			return -1;
		}
	} else {
		strtab = mmap(NULL, symstrsize, PROT_READ, MAP_SHARED|MAP_FILE,
		    fd, symstroff);
		if (strtab == MAP_FAILED)
			return -1;
	}

	while (symsize >= sizeof(Elf_Sym)) {
		cc = MINIMUM(symsize, sizeof(sbuf));
		if (pread(fd, sbuf, cc, symoff) != cc)
			break;
		symsize -= cc;
		symoff += cc;
		for (s = sbuf; cc > 0; ++s, cc -= sizeof(*s)) {
			Elf_Word soff = s->st_name;

			if (soff == 0 || soff >= symstrsize)
				continue;
			left = symstrsize - soff;

			for (p = list; !ISLAST(p); p++) {
				char *sym;

				/*
				 * First we check for the symbol as it was
				 * provided by the user. If that fails
				 * and the first char is an '_', skip over
				 * the '_' and try again.
				 * XXX - What do we do when the user really
				 *       wants '_foo' and there are symbols
				 *       for both 'foo' and '_foo' in the
				 *	 table and 'foo' is first?
				 */
				sym = p->n_name;
				len = strlen(sym);

				if ((len >= left ||
				    strcmp(&strtab[soff], sym) != 0) &&
				    (sym[0] != '_' || len - 1 >= left ||
				     strcmp(&strtab[soff], sym + 1) != 0))
					continue;

				p->n_value = s->st_value;

				/* XXX - type conversion */
				/*	 is pretty rude. */
				switch(ELF_ST_TYPE(s->st_info)) {
				case STT_NOTYPE:
					switch (s->st_shndx) {
					case SHN_UNDEF:
						p->n_type = N_UNDF;
						break;
					case SHN_ABS:
						p->n_type = N_ABS;
						break;
					case SHN_COMMON:
						p->n_type = N_COMM;
						break;
					default:
						p->n_type = N_COMM | N_EXT;
						break;
					}
					break;
				case STT_OBJECT:
					p->n_type = N_DATA;
					break;
				case STT_FUNC:
					p->n_type = N_TEXT;
					break;
				case STT_FILE:
					p->n_type = N_FN;
					break;
				}
				if (ELF_ST_BIND(s->st_info) == STB_LOCAL)
					p->n_type = N_EXT;
				p->n_desc = 0;
				p->n_other = 0;
				if (--nent <= 0)
					break;
			}
		}
	}
	if (usemalloc)
		free(strtab);
	else
		munmap(strtab, symstrsize);
	return nent;
}

int nlist(const char *name, struct nlist *list)
{
	int fd, n;

	fd = open(name, O_RDONLY | O_CLOEXEC);
	if (fd == -1)
		return -1;
	n = __fdnlist(fd, list);
	(void)close(fd);
	return n;
}
