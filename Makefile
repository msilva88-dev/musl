#
# Makefile for musl (requires GNU make)
#
# This is how simple every makefile should be...
# No, I take that back - actually most should be less than half this size.
#
# Use config.mak to override any of the following variables.
# Do not make changes here.
#

srcdir = .
objbuilddir = obj
libbuilddir = lib

exec_prefix = /usr/local
bindir = $(exec_prefix)/bin

prefix = /usr/local/musl
includedir = $(prefix)/include
libdir = $(prefix)/lib
syslibdir = /lib

LDFLAGS =
LDFLAGS_AUTO =
LIBCC = -lgcc
CPPFLAGS =
CFLAGS =
CFLAGS_AUTO = -Os -pipe
CFLAGS_C99FSE = -std=c99 -ffreestanding -nostdinc

CFLAGS_ALL = $(CFLAGS_C99FSE)
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I$(srcdir)/arch/$(ARCH)
CFLAGS_ALL += -I$(srcdir)/arch/generic -I$(objbuilddir)/src/internal
CFLAGS_ALL += -I$(srcdir)/src/include -I$(srcdir)/src/internal
CFLAGS_ALL += -I$(objbuilddir)/include -I$(srcdir)/include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS_AUTO) $(CFLAGS)

LDFLAGS_ALL = $(LDFLAGS_AUTO) $(LDFLAGS)

AR = $(CROSS_COMPILE)ar
RANLIB = $(CROSS_COMPILE)ranlib
INSTALL = $(srcdir)/tools/install.sh

TOOL_LIBS = $(libbuilddir)/musl-gcc.specs
ALL_TOOLS = $(objbuilddir)/musl-gcc

WRAPCC_GCC = gcc
WRAPCC_CLANG = clang

MALLOC_DIR = mallocng

include config.mak

SRC_DIRS != \
printf "%s\n" $(srcdir)/src/* $(srcdir)/src/malloc/$(MALLOC_DIR) \
  $(srcdir)/crt $(srcdir)/ldso; \
cpt=$(COMPAT_SRC_DIRS) && [ $${cpt} ] \
  && printf "%s\n" $(srcdir)/$(COMPAT_SRC_DIRS) || true;
BASE_GLOBS := $(SRC_DIRS:%=%/*.c)
ARCH_GLOBS := $(SRC_DIRS:%=%/$(ARCH)/*.[csS])
BASE_SRCS != \
for g in $(BASE_GLOBS); do \
    for f in "$${g}"; do \
        [ -f "$${f}" ] && printf "%s\n" "$${f}" || true; \
    done; \
done | sort -u
ARCH_SRCS != \
for g in $(ARCH_GLOBS); do \
    for f in "$${g}"; do \
        [ -f "$${f}" ] && printf "%s\n" "$${f}" || true; \
    done; \
done | sort -u
BASE_OBJS := $(BASE_SRCS:$(srcdir)/%.c=%.o)
ARCH_OBJS := $(ARCH_SRCS:$(srcdir)/%.c=%.o)
ARCH_OBJS := $(ARCH_OBJS:$(srcdir)/%.s=%.o)
ARCH_OBJS := $(ARCH_OBJS:$(srcdir)/%.S=%.o)
REPLACED_OBJS != printf "%s\n" $(ARCH_OBJS) | sed 's|/$(ARCH)/|/|g' | sort -u
ALL_OBJS_BASE != printf "%s\n" $(BASE_OBJS) $(ARCH_OBJS) | sort -u
ALL_OBJS != \
printf "$(objbuilddir)/%s\n" $(ALL_OBJS_BASE) \
  | awk 'BEGIN { \
    '"$$( \
        for x in $(REPLACED_OBJS); do \
            printf "%s\n" "skip[\"$(objbuilddir)/$${x}\"]=1;"; \
        done \
    )"' \
} { \
    if (!skip[$$0]) print $$0 \
}'

LIBC_OBJS != \
for o in $(ALL_OBJS); do \
    case "$${o}" in \
        $(objbuilddir)/src/*) printf "%s\n" "$${o}";; \
    esac; \
done; \
for o in $(ALL_OBJS); do \
    case "$${o}" in \
        $(objbuilddir)/compat/*) printf "%s\n" "$${o}";; \
    esac; \
done
LDSO_OBJS != \
for o in $(ALL_OBJS:%.o=%.lo); do \
    case "$${o}" in \
        $(objbuilddir)/ldso/*) printf "%s\n" "$${o}";; \
    esac; \
done
CRT_OBJS != \
for o in $(ALL_OBJS); do \
    case "$${o}" in \
        $(objbuilddir)/crt/*) printf "%s\n" "$${o}";; \
    esac; \
done

AOBJS := $(LIBC_OBJS)
LOBJS := $(LIBC_OBJS:.o=.lo)
GENH = $(objbuilddir)/include/bits/alltypes.h $(objbuilddir)/include/bits/syscall.h
GENH_INT = $(objbuilddir)/src/internal/version.h
IMPH = $(srcdir)/src/internal/stdio_impl.h
IMPH += $(srcdir)/src/internal/pthread_impl.h
IMPH += $(srcdir)/src/internal/locale_impl.h
IMPH += $(srcdir)/src/internal/libc.h

ARCH_INCLUDES != \
for i in $(srcdir)/arch/$(ARCH)/bits/*.h; do \
    [ -f "$${i}" ] && printf "%s\n" "$${i}" || true; \
done
GENERIC_INCLUDES != \
for i in $(srcdir)/arch/generic/bits/*.h; do \
    [ -f "$${i}" ] && printf "%s\n" "$${i}" || true; \
done
INCLUDES != \
for i in $(srcdir)/include/*.h $(srcdir)/include/*/*.h; do \
    [ -f "$${i}" ] && printf "%s\n" "$${i}" || true; \
done
ALL_INCLUDES != \
printf "%s\n" $(INCLUDES:$(srcdir)/%=%) $(GENH:$(objbuilddir)/%=%) \
  $(ARCH_INCLUDES:$(srcdir)/arch/$(ARCH)/%=include/%) \
  $(GENERIC_INCLUDES:$(srcdir)/arch/generic/%=include/%) \
  | sort -u

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=$(libbuilddir)/lib%.a)
CRT_LIBS != \
for l in $(CRT_OBJS); do \
    printf "$(libbuilddir)/%s\n" "$$(basename $${l})"; \
done
STATIC_LIBS = $(libbuilddir)/libc.a
SHARED_LIBS = $(libbuilddir)/libc.so
ALL_LIBS := $(CRT_LIBS) $(STATIC_LIBS) $(SHARED_LIBS)
ALL_LIBS += $(EMPTY_LIBS) $(TOOL_LIBS)

LDSO_PATHNAME = $(syslibdir)/ld-musl-$(ARCH)$(SUBARCH).so.1

COMPAT_SRC_DIRS != \
case "$(ARCH)" in \
    arm|i386|m68k|microblaze|mips|mipsn32|or1k|powerpc|sh) \
        printf "%s\n" "compat/time32" \
        ;; \
    *) \
        printf "%s\n" "" \
        ;; \
esac

all: arch $(ALL_LIBS) $(ALL_TOOLS)

arch:
	@if [ -z "$(ARCH)" ]; then \
	    printf "%s\n" \
	      "Please set ARCH in config.mak before running make."; \
	    exit 1; \
	fi

OBJ_DIRS != ( \
    for f in $(ALL_LIBS) $(ALL_TOOLS) $(ALL_OBJS) $(GENH) $(GENH_INT); do \
        d=$$(dirname "$${f}"); \
        d=$${d%/}; \
        printf "%s\n" "$${d}"; \
    done; \
    printf "%s\n" "$(objbuilddir)/include"; \
) | sort -u

$(ALL_LIBS) $(ALL_TOOLS) $(ALL_OBJS) $(ALL_OBJS:%.o=%.lo) \
  $(GENH) $(GENH_INT): $(OBJ_DIRS)

$(OBJ_DIRS):
	mkdir -p $@

$(objbuilddir)/include/bits/alltypes.h: \
  $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in $(srcdir)/include/alltypes.h.in \
  $(srcdir)/tools/mkalltypes.sed
	sed -f $(srcdir)/tools/mkalltypes.sed \
	  $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in \
	  $(srcdir)/include/alltypes.h.in \
	  > $@

$(objbuilddir)/include/bits/syscall.h: \
  $(srcdir)/arch/$(ARCH)/bits/syscall.h.in
	cp $< $@
	sed -n -e s/__NR_/SYS_/p < $< >> $@

VERSION_FILES != \
sep=""; \
for f in $(srcdir)/VERSION $(srcdir)/.git; do \
    [ -e "$${f}" ] && printf "%s%s" "$${sep}" "$${f}" && sep=" " || true; \
done
$(objbuilddir)/src/internal/version.h: $(VERSION_FILES)
	printf '#define VERSION "%s"\n' \
	  "$$(cd $(srcdir); sh tools/version.sh)" > $@

$(objbuilddir)/src/internal/version.o \
  $(objbuilddir)/src/internal/version.lo: \
  $(objbuilddir)/src/internal/version.h

$(objbuilddir)/crt/rcrt1.o $(objbuilddir)/ldso/dlstart.lo \
  $(objbuilddir)/ldso/dynlink.lo: \
  $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h

$(objbuilddir)/crt/crt1.o $(objbuilddir)/crt/Scrt1.o \
  $(objbuilddir)/crt/rcrt1.o $(objbuilddir)/ldso/dlstart.lo: \
  $(srcdir)/arch/$(ARCH)/crt_arch.h

$(objbuilddir)/crt/rcrt1.o: $(srcdir)/ldso/dlstart.c

$(objbuilddir)/crt/Scrt1.o $(objbuilddir)/crt/rcrt1.o: CFLAGS_ALL += -fPIC

OPTIMIZE_SRCS != \
for s in $(OPTIMIZE_GLOBS:%=$(srcdir)/src/%); do \
    [ -f "$${s}" ] && printf "%s\n" "$${s}" || true; \
done
$(OPTIMIZE_SRCS:$(srcdir)/%.c=$(objbuilddir)/%.o) \
  $(OPTIMIZE_SRCS:$(srcdir)/%.c=$(objbuilddir)/%.lo): CFLAGS += -O3

MEMOPS_OBJS != \
for o in $(LIBC_OBJS); do \
    case "$${o}" in \
        */memcpy.o|*/memmove.o|*/memcmp.o|*/memset.o) \
            printf "%s\n" "$${o}" \
            ;; \
    esac; \
done
$(MEMOPS_OBJS) $(MEMOPS_OBJS:%.o=%.lo): CFLAGS_ALL += $(CFLAGS_MEMOPS)

NOSSP_OBJS != \
for o in $(CRT_OBJS); do \
    printf "%s\n" "$${o}"; \
done; \
for o in $(LDSO_OBJS); do \
    printf "%s\n" "$${o}"; \
done; \
for o in $(LIBC_OBJS); do \
    case "$${o}" in \
        */__libc_start_main.o|*/__init_tls.o|*/__stack_chk_fail.o \
        |*/__set_thread_area.o|*/memset.o|*/memcpy.o) \
            printf "%s\n" "$${o}" \
            ;; \
    esac; \
done
$(NOSSP_OBJS) $(NOSSP_OBJS:%.o=%.lo): CFLAGS_ALL += $(CFLAGS_NOSSP)

$(CRT_OBJS): CFLAGS_ALL += -DCRT

$(LOBJS) $(LDSO_OBJS): CFLAGS_ALL += -fPIC

CC_CMD = $(CC) $(CFLAGS_ALL) -c -o
AS_CMD0 = LC_ALL=C awk -f $(srcdir)/tools/add-cfi.common.awk
AS_CMD0 += -f $(srcdir)/tools/add-cfi.$(ARCH).awk
AS_CMD1 = $(CC) $(CFLAGS_ALL) -x assembler -c -o

$(objbuilddir)/crt/aarch64/crti.o: $(srcdir)/crt/aarch64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/aarch64/crtn.o: $(srcdir)/crt/aarch64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/arm/crti.o: $(srcdir)/crt/arm/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/arm/crtn.o: $(srcdir)/crt/arm/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/i386/crti.o: $(srcdir)/crt/i386/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/i386/crtn.o: $(srcdir)/crt/i386/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/microblaze/crti.o: $(srcdir)/crt/microblaze/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/microblaze/crtn.o: $(srcdir)/crt/microblaze/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips/crti.o: $(srcdir)/crt/mips/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips/crtn.o: $(srcdir)/crt/mips/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips64/crti.o: $(srcdir)/crt/mips64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips64/crtn.o: $(srcdir)/crt/mips64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mipsn32/crti.o: $(srcdir)/crt/mipsn32/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mipsn32/crtn.o: $(srcdir)/crt/mipsn32/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/or1k/crti.o: $(srcdir)/crt/or1k/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/or1k/crtn.o: $(srcdir)/crt/or1k/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc/crti.o: $(srcdir)/crt/powerpc/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc/crtn.o: $(srcdir)/crt/powerpc/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc64/crti.o: $(srcdir)/crt/powerpc64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc64/crtn.o: $(srcdir)/crt/powerpc64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/s390x/crti.o: $(srcdir)/crt/s390x/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/s390x/crtn.o: $(srcdir)/crt/s390x/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/sh/crti.o: $(srcdir)/crt/sh/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/sh/crtn.o: $(srcdir)/crt/sh/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x32/crti.o: $(srcdir)/crt/x32/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x32/crtn.o: $(srcdir)/crt/x32/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x86_64/crti.o: $(srcdir)/crt/x86_64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x86_64/crtn.o: $(srcdir)/crt/x86_64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/aarch64/fenv.o: $(srcdir)/src/fenv/aarch64/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/i386/fenv.o: $(srcdir)/src/fenv/i386/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/x32/fenv.o: $(srcdir)/src/fenv/x32/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/x86_64/fenv.o: $(srcdir)/src/fenv/x86_64/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/internal/i386/defsysinfo.o: $(srcdir)/src/internal/i386/defsysinfo.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/aarch64/dlsym.o: $(srcdir)/src/ldso/aarch64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/aarch64/tlsdesc.o: $(srcdir)/src/ldso/aarch64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/arm/dlsym.o: $(srcdir)/src/ldso/arm/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/i386/dlsym.o: $(srcdir)/src/ldso/i386/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/i386/tlsdesc.o: $(srcdir)/src/ldso/i386/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/loongarch64/dlsym.o: $(srcdir)/src/ldso/loongarch64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/loongarch64/tlsdesc.o: $(srcdir)/src/ldso/loongarch64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/m68k/dlsym.o: $(srcdir)/src/ldso/m68k/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/microblaze/dlsym.o: $(srcdir)/src/ldso/microblaze/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mips/dlsym.o: $(srcdir)/src/ldso/mips/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mips64/dlsym.o: $(srcdir)/src/ldso/mips64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mipsn32/dlsym.o: $(srcdir)/src/ldso/mipsn32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/or1k/dlsym.o: $(srcdir)/src/ldso/or1k/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/powerpc/dlsym.o: $(srcdir)/src/ldso/powerpc/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/powerpc64/dlsym.o: $(srcdir)/src/ldso/powerpc64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv32/dlsym.o: $(srcdir)/src/ldso/riscv32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv64/dlsym.o: $(srcdir)/src/ldso/riscv64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv64/tlsdesc.o: $(srcdir)/src/ldso/riscv64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/s390x/dlsym.o: $(srcdir)/src/ldso/s390x/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/sh/dlsym.o: $(srcdir)/src/ldso/sh/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x32/dlsym.o: $(srcdir)/src/ldso/x32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x86_64/dlsym.o: $(srcdir)/src/ldso/x86_64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x86_64/tlsdesc.o: $(srcdir)/src/ldso/x86_64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/__invtrigl.o: $(srcdir)/src/math/i386/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acos.o: $(srcdir)/src/math/i386/acos.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acosf.o: $(srcdir)/src/math/i386/acosf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acosl.o: $(srcdir)/src/math/i386/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asin.o: $(srcdir)/src/math/i386/asin.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asinf.o: $(srcdir)/src/math/i386/asinf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asinl.o: $(srcdir)/src/math/i386/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan.o: $(srcdir)/src/math/i386/atan.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2.o: $(srcdir)/src/math/i386/atan2.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2f.o: $(srcdir)/src/math/i386/atan2f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2l.o: $(srcdir)/src/math/i386/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atanf.o: $(srcdir)/src/math/i386/atanf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atanl.o: $(srcdir)/src/math/i386/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceil.o: $(srcdir)/src/math/i386/ceil.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceilf.o: $(srcdir)/src/math/i386/ceilf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceill.o: $(srcdir)/src/math/i386/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/exp_ld.o: $(srcdir)/src/math/i386/exp_ld.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/exp2l.o: $(srcdir)/src/math/i386/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/expl.o: $(srcdir)/src/math/i386/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/expm1l.o: $(srcdir)/src/math/i386/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floor.o: $(srcdir)/src/math/i386/floor.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floorf.o: $(srcdir)/src/math/i386/floorf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floorl.o: $(srcdir)/src/math/i386/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/hypot.o: $(srcdir)/src/math/i386/hypot.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/hypotf.o: $(srcdir)/src/math/i386/hypotf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexp.o: $(srcdir)/src/math/i386/ldexp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexpf.o: $(srcdir)/src/math/i386/ldexpf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexpl.o: $(srcdir)/src/math/i386/ldexpl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log.o: $(srcdir)/src/math/i386/log.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10.o: $(srcdir)/src/math/i386/log10.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10f.o: $(srcdir)/src/math/i386/log10f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10l.o: $(srcdir)/src/math/i386/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1p.o: $(srcdir)/src/math/i386/log1p.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1pf.o: $(srcdir)/src/math/i386/log1pf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1pl.o: $(srcdir)/src/math/i386/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2.o: $(srcdir)/src/math/i386/log2.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2f.o: $(srcdir)/src/math/i386/log2f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2l.o: $(srcdir)/src/math/i386/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/logf.o: $(srcdir)/src/math/i386/logf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/logl.o: $(srcdir)/src/math/i386/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquo.o: $(srcdir)/src/math/i386/remquo.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquof.o: $(srcdir)/src/math/i386/remquof.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquol.o: $(srcdir)/src/math/i386/remquol.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbln.o: $(srcdir)/src/math/i386/scalbln.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalblnf.o: $(srcdir)/src/math/i386/scalblnf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalblnl.o: $(srcdir)/src/math/i386/scalblnl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbn.o: $(srcdir)/src/math/i386/scalbn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbnf.o: $(srcdir)/src/math/i386/scalbnf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbnl.o: $(srcdir)/src/math/i386/scalbnl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/trunc.o: $(srcdir)/src/math/i386/trunc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/truncf.o: $(srcdir)/src/math/i386/truncf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/truncl.o: $(srcdir)/src/math/i386/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/__invtrigl.o: $(srcdir)/src/math/x32/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/acosl.o: $(srcdir)/src/math/x32/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/asinl.o: $(srcdir)/src/math/x32/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/atan2l.o: $(srcdir)/src/math/x32/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/atanl.o: $(srcdir)/src/math/x32/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/ceill.o: $(srcdir)/src/math/x32/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/exp2l.o: $(srcdir)/src/math/x32/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/expl.o: $(srcdir)/src/math/x32/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/expm1l.o: $(srcdir)/src/math/x32/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabs.o: $(srcdir)/src/math/x32/fabs.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabsf.o: $(srcdir)/src/math/x32/fabsf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabsl.o: $(srcdir)/src/math/x32/fabsl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/floorl.o: $(srcdir)/src/math/x32/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fmodl.o: $(srcdir)/src/math/x32/fmodl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrint.o: $(srcdir)/src/math/x32/llrint.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrintf.o: $(srcdir)/src/math/x32/llrintf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrintl.o: $(srcdir)/src/math/x32/llrintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log10l.o: $(srcdir)/src/math/x32/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log1pl.o: $(srcdir)/src/math/x32/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log2l.o: $(srcdir)/src/math/x32/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/logl.o: $(srcdir)/src/math/x32/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrint.o: $(srcdir)/src/math/x32/lrint.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrintf.o: $(srcdir)/src/math/x32/lrintf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrintl.o: $(srcdir)/src/math/x32/lrintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/remainderl.o: $(srcdir)/src/math/x32/remainderl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/rintl.o: $(srcdir)/src/math/x32/rintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrt.o: $(srcdir)/src/math/x32/sqrt.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrtf.o: $(srcdir)/src/math/x32/sqrtf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrtl.o: $(srcdir)/src/math/x32/sqrtl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/truncl.o: $(srcdir)/src/math/x32/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/__invtrigl.o: $(srcdir)/src/math/x86_64/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/acosl.o: $(srcdir)/src/math/x86_64/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/asinl.o: $(srcdir)/src/math/x86_64/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/atan2l.o: $(srcdir)/src/math/x86_64/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/atanl.o: $(srcdir)/src/math/x86_64/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/ceill.o: $(srcdir)/src/math/x86_64/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/exp2l.o: $(srcdir)/src/math/x86_64/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/expl.o: $(srcdir)/src/math/x86_64/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/expm1l.o: $(srcdir)/src/math/x86_64/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/floorl.o: $(srcdir)/src/math/x86_64/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log10l.o: $(srcdir)/src/math/x86_64/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log1pl.o: $(srcdir)/src/math/x86_64/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log2l.o: $(srcdir)/src/math/x86_64/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/logl.o: $(srcdir)/src/math/x86_64/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/truncl.o: $(srcdir)/src/math/x86_64/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/aarch64/vfork.o: $(srcdir)/src/process/aarch64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/arm/vfork.o: $(srcdir)/src/process/arm/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/i386/vfork.o: $(srcdir)/src/process/i386/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/riscv64/vfork.o: $(srcdir)/src/process/riscv64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/s390x/vfork.o: $(srcdir)/src/process/s390x/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/sh/vfork.o: $(srcdir)/src/process/sh/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/x32/vfork.o: $(srcdir)/src/process/x32/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/x86_64/vfork.o: $(srcdir)/src/process/x86_64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/aarch64/longjmp.o: $(srcdir)/src/setjmp/aarch64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/aarch64/setjmp.o: $(srcdir)/src/setjmp/aarch64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/i386/longjmp.o: $(srcdir)/src/setjmp/i386/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/i386/setjmp.o: $(srcdir)/src/setjmp/i386/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/m68k/longjmp.o: $(srcdir)/src/setjmp/m68k/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/m68k/setjmp.o: $(srcdir)/src/setjmp/m68k/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/microblaze/longjmp.o: $(srcdir)/src/setjmp/microblaze/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/microblaze/setjmp.o: $(srcdir)/src/setjmp/microblaze/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/or1k/longjmp.o: $(srcdir)/src/setjmp/or1k/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/or1k/setjmp.o: $(srcdir)/src/setjmp/or1k/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/powerpc64/longjmp.o: $(srcdir)/src/setjmp/powerpc64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/powerpc64/setjmp.o: $(srcdir)/src/setjmp/powerpc64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/s390x/longjmp.o: $(srcdir)/src/setjmp/s390x/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/s390x/setjmp.o: $(srcdir)/src/setjmp/s390x/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x32/longjmp.o: $(srcdir)/src/setjmp/x32/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x32/setjmp.o: $(srcdir)/src/setjmp/x32/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x86_64/longjmp.o: $(srcdir)/src/setjmp/x86_64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x86_64/setjmp.o: $(srcdir)/src/setjmp/x86_64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/aarch64/restore.o: $(srcdir)/src/signal/aarch64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/aarch64/sigsetjmp.o: $(srcdir)/src/signal/aarch64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/arm/restore.o: $(srcdir)/src/signal/arm/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/arm/sigsetjmp.o: $(srcdir)/src/signal/arm/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/i386/restore.o: $(srcdir)/src/signal/i386/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/i386/sigsetjmp.o: $(srcdir)/src/signal/i386/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/loongarch64/restore.o: \
  $(srcdir)/src/signal/loongarch64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/loongarch64/sigsetjmp.o: \
  $(srcdir)/src/signal/loongarch64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/m68k/sigsetjmp.o: $(srcdir)/src/signal/m68k/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/microblaze/restore.o: $(srcdir)/src/signal/microblaze/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/microblaze/sigsetjmp.o: \
  $(srcdir)/src/signal/microblaze/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mips/sigsetjmp.o: $(srcdir)/src/signal/mips/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mips64/sigsetjmp.o: $(srcdir)/src/signal/mips64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mipsn32/sigsetjmp.o: $(srcdir)/src/signal/mipsn32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/or1k/sigsetjmp.o: $(srcdir)/src/signal/or1k/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc/restore.o: $(srcdir)/src/signal/powerpc/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc/sigsetjmp.o: $(srcdir)/src/signal/powerpc/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc64/restore.o: $(srcdir)/src/signal/powerpc64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc64/sigsetjmp.o: \
  $(srcdir)/src/signal/powerpc64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv32/restore.o: $(srcdir)/src/signal/riscv32/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv32/sigsetjmp.o: $(srcdir)/src/signal/riscv32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv64/restore.o: $(srcdir)/src/signal/riscv64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv64/sigsetjmp.o: $(srcdir)/src/signal/riscv64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/s390x/restore.o: $(srcdir)/src/signal/s390x/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/s390x/sigsetjmp.o: $(srcdir)/src/signal/s390x/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/sh/restore.o: $(srcdir)/src/signal/sh/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/sh/sigsetjmp.o: $(srcdir)/src/signal/sh/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x32/restore.o: $(srcdir)/src/signal/x32/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x32/sigsetjmp.o: $(srcdir)/src/signal/x32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x86_64/restore.o: $(srcdir)/src/signal/x86_64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x86_64/sigsetjmp.o: $(srcdir)/src/signal/x86_64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/arm/__aeabi_memcpy.o: $(srcdir)/src/string/arm/__aeabi_memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/arm/__aeabi_memset.o: $(srcdir)/src/string/arm/__aeabi_memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memcpy.o: $(srcdir)/src/string/i386/memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memmove.o: $(srcdir)/src/string/i386/memmove.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memset.o: $(srcdir)/src/string/i386/memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memcpy.o: $(srcdir)/src/string/x86_64/memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memmove.o: $(srcdir)/src/string/x86_64/memmove.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memset.o: $(srcdir)/src/string/x86_64/memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/__unmapself.o: \
  $(srcdir)/src/thread/aarch64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/clone.o: $(srcdir)/src/thread/aarch64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/syscall_cp.o: $(srcdir)/src/thread/aarch64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/__aeabi_read_tp.o: \
  $(srcdir)/src/thread/arm/__aeabi_read_tp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/__unmapself.o: $(srcdir)/src/thread/arm/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/atomics.o: $(srcdir)/src/thread/arm/atomics.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/clone.o: $(srcdir)/src/thread/arm/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/syscall_cp.o: $(srcdir)/src/thread/arm/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/__set_thread_area.o: \
  $(srcdir)/src/thread/i386/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/__unmapself.o: $(srcdir)/src/thread/i386/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/clone.o: $(srcdir)/src/thread/i386/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/syscall_cp.o: $(srcdir)/src/thread/i386/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/tls.o: $(srcdir)/src/thread/i386/tls.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/__set_thread_area.o: \
  $(srcdir)/src/thread/loongarch64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/__unmapself.o: \
  $(srcdir)/src/thread/loongarch64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/clone.o: $(srcdir)/src/thread/loongarch64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/syscall_cp.o: \
  $(srcdir)/src/thread/loongarch64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/__m68k_read_tp.o: \
  $(srcdir)/src/thread/m68k/__m68k_read_tp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/clone.o: $(srcdir)/src/thread/m68k/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/syscall_cp.o: $(srcdir)/src/thread/m68k/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/__set_thread_area.o: \
  $(srcdir)/src/thread/microblaze/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/__unmapself.o: \
  $(srcdir)/src/thread/microblaze/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/clone.o: $(srcdir)/src/thread/microblaze/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/syscall_cp.o: \
  $(srcdir)/src/thread/microblaze/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/__unmapself.o: $(srcdir)/src/thread/mips/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/clone.o: $(srcdir)/src/thread/mips/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/syscall_cp.o: $(srcdir)/src/thread/mips/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/__unmapself.o: $(srcdir)/src/thread/mips64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/clone.o: $(srcdir)/src/thread/mips64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/syscall_cp.o: $(srcdir)/src/thread/mips64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/__unmapself.o: \
  $(srcdir)/src/thread/mipsn32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/clone.o: $(srcdir)/src/thread/mipsn32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/syscall_cp.o: $(srcdir)/src/thread/mipsn32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/__set_thread_area.o: \
  $(srcdir)/src/thread/or1k/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/__unmapself.o: $(srcdir)/src/thread/or1k/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/clone.o: $(srcdir)/src/thread/or1k/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/syscall_cp.o: $(srcdir)/src/thread/or1k/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/__set_thread_area.o: \
  $(srcdir)/src/thread/powerpc/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/__unmapself.o: \
  $(srcdir)/src/thread/powerpc/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/clone.o: $(srcdir)/src/thread/powerpc/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/syscall_cp.o: $(srcdir)/src/thread/powerpc/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/__set_thread_area.o: \
  $(srcdir)/src/thread/powerpc64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/__unmapself.o: \
  $(srcdir)/src/thread/powerpc64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/clone.o: $(srcdir)/src/thread/powerpc64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/syscall_cp.o: \
  $(srcdir)/src/thread/powerpc64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/__set_thread_area.o: \
  $(srcdir)/src/thread/riscv32/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/__unmapself.o: \
  $(srcdir)/src/thread/riscv32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/clone.o: $(srcdir)/src/thread/riscv32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/syscall_cp.o: $(srcdir)/src/thread/riscv32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/__set_thread_area.o: \
  $(srcdir)/src/thread/riscv64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/__unmapself.o: \
  $(srcdir)/src/thread/riscv64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/clone.o: $(srcdir)/src/thread/riscv64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/syscall_cp.o: $(srcdir)/src/thread/riscv64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__set_thread_area.o: \
  $(srcdir)/src/thread/s390x/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__unmapself.o: $(srcdir)/src/thread/s390x/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__tls_get_offset.o: \
  $(srcdir)/src/thread/s390x/__tls_get_offset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/clone.o: $(srcdir)/src/thread/s390x/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/syscall_cp.o: $(srcdir)/src/thread/s390x/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/__unmapself_mmu.o: $(srcdir)/src/thread/sh/__unmapself_mmu.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/atomics.o: $(srcdir)/src/thread/sh/atomics.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/clone.o: $(srcdir)/src/thread/sh/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/syscall_cp.o: $(srcdir)/src/thread/sh/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/__set_thread_area.o: \
  $(srcdir)/src/thread/x32/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/__unmapself.o: $(srcdir)/src/thread/x32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/clone.o: $(srcdir)/src/thread/x32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/syscall_cp.o: $(srcdir)/src/thread/x32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/__set_thread_area.o: \
  $(srcdir)/src/thread/x86_64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/__unmapself.o: $(srcdir)/src/thread/x86_64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/clone.o: $(srcdir)/src/thread/x86_64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/syscall_cp.o: $(srcdir)/src/thread/x86_64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mips/pipe.o: $(srcdir)/src/unistd/mips/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mips64/pipe.o: $(srcdir)/src/unistd/mips64/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mipsn32/pipe.o: $(srcdir)/src/unistd/mipsn32/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/sh/pipe.o: $(srcdir)/src/unistd/sh/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi

$(objbuilddir)/src/fenv/arm/fenv-hf.o: $(srcdir)/src/fenv/arm/fenv-hf.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/loongarch64/fenv.o: $(srcdir)/src/fenv/loongarch64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips/fenv.o: $(srcdir)/src/fenv/mips/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips64/fenv.o: $(srcdir)/src/fenv/mips64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mipsn32/fenv.o: $(srcdir)/src/fenv/mipsn32/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc/fenv.o: $(srcdir)/src/fenv/powerpc/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv32/fenv.o: $(srcdir)/src/fenv/riscv32/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv64/fenv.o: $(srcdir)/src/fenv/riscv64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/sh/fenv.o: $(srcdir)/src/fenv/sh/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/dlsym_time64.o: $(srcdir)/src/ldso/arm/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/tlsdesc.o: $(srcdir)/src/ldso/arm/tlsdesc.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/i386/dlsym_time64.o: $(srcdir)/src/ldso/i386/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/m68k/dlsym_time64.o: $(srcdir)/src/ldso/m68k/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/microblaze/dlsym_time64.o: \
  $(srcdir)/src/ldso/microblaze/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/mips/dlsym_time64.o: $(srcdir)/src/ldso/mips/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/mipsn32/dlsym_time64.o: $(srcdir)/src/ldso/mipsn32/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/or1k/dlsym_time64.o: $(srcdir)/src/ldso/or1k/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/powerpc/dlsym_time64.o: $(srcdir)/src/ldso/powerpc/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/sh/dlsym_time64.o: $(srcdir)/src/ldso/sh/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/arm/longjmp.o: $(srcdir)/src/setjmp/arm/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/arm/setjmp.o: $(srcdir)/src/setjmp/arm/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/loongarch64/longjmp.o: \
  $(srcdir)/src/setjmp/loongarch64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/loongarch64/setjmp.o: $(srcdir)/src/setjmp/loongarch64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips/longjmp.o: $(srcdir)/src/setjmp/mips/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips/setjmp.o: $(srcdir)/src/setjmp/mips/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips64/longjmp.o: $(srcdir)/src/setjmp/mips64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips64/setjmp.o: $(srcdir)/src/setjmp/mips64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mipsn32/longjmp.o: $(srcdir)/src/setjmp/mipsn32/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mipsn32/setjmp.o: $(srcdir)/src/setjmp/mipsn32/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/powerpc/longjmp.o: $(srcdir)/src/setjmp/powerpc/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/powerpc/setjmp.o: $(srcdir)/src/setjmp/powerpc/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv32/longjmp.o: $(srcdir)/src/setjmp/riscv32/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv32/setjmp.o: $(srcdir)/src/setjmp/riscv32/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv64/longjmp.o: $(srcdir)/src/setjmp/riscv64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv64/setjmp.o: $(srcdir)/src/setjmp/riscv64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/sh/longjmp.o: $(srcdir)/src/setjmp/sh/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/sh/setjmp.o: $(srcdir)/src/setjmp/sh/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/aarch64/memcpy.o: $(srcdir)/src/string/aarch64/memcpy.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/aarch64/memset.o: $(srcdir)/src/string/aarch64/memset.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/arm/memcpy.o: $(srcdir)/src/string/arm/memcpy.S
	$(CC_CMD) $@ $<

$(objbuilddir)/compat/time32/__xstat.o: $(srcdir)/compat/time32/__xstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/adjtime32.o: $(srcdir)/compat/time32/adjtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/adjtimex_time32.o: \
  $(srcdir)/compat/time32/adjtimex_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/aio_suspend_time32.o: \
  $(srcdir)/compat/time32/aio_suspend_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_adjtime32.o: \
  $(srcdir)/compat/time32/clock_adjtime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_getres_time32.o: \
  $(srcdir)/compat/time32/clock_getres_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_gettime32.o: \
  $(srcdir)/compat/time32/clock_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_nanosleep_time32.o: \
  $(srcdir)/compat/time32/clock_nanosleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_settime32.o: \
  $(srcdir)/compat/time32/clock_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/cnd_timedwait_time32.o: \
  $(srcdir)/compat/time32/cnd_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ctime32.o: $(srcdir)/compat/time32/ctime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ctime32_r.o: $(srcdir)/compat/time32/ctime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/difftime32.o: $(srcdir)/compat/time32/difftime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/fstat_time32.o: $(srcdir)/compat/time32/fstat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/fstatat_time32.o: $(srcdir)/compat/time32/fstatat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ftime32.o: $(srcdir)/compat/time32/ftime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimens_time32.o: \
  $(srcdir)/compat/time32/futimens_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimes_time32.o: $(srcdir)/compat/time32/futimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimesat_time32.o: \
  $(srcdir)/compat/time32/futimesat_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/getitimer_time32.o: \
  $(srcdir)/compat/time32/getitimer_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/getrusage_time32.o: \
  $(srcdir)/compat/time32/getrusage_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gettimeofday_time32.o: \
  $(srcdir)/compat/time32/gettimeofday_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gmtime32.o: $(srcdir)/compat/time32/gmtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gmtime32_r.o: $(srcdir)/compat/time32/gmtime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/localtime32.o: $(srcdir)/compat/time32/localtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/localtime32_r.o: $(srcdir)/compat/time32/localtime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/lstat_time32.o: $(srcdir)/compat/time32/lstat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/lutimes_time32.o: $(srcdir)/compat/time32/lutimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mktime32.o: $(srcdir)/compat/time32/mktime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mq_timedreceive_time32.o: \
  $(srcdir)/compat/time32/mq_timedreceive_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mq_timedsend_time32.o: \
  $(srcdir)/compat/time32/mq_timedsend_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mtx_timedlock_time32.o: \
  $(srcdir)/compat/time32/mtx_timedlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/nanosleep_time32.o: \
  $(srcdir)/compat/time32/nanosleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ppoll_time32.o: $(srcdir)/compat/time32/ppoll_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pselect_time32.o: $(srcdir)/compat/time32/pselect_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_cond_timedwait_time32.o: \
  $(srcdir)/compat/time32/pthread_cond_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_mutex_timedlock_time32.o: \
  $(srcdir)/compat/time32/pthread_mutex_timedlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_rwlock_timedrdlock_time32.o: \
  $(srcdir)/compat/time32/pthread_rwlock_timedrdlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_rwlock_timedwrlock_time32.o: \
  $(srcdir)/compat/time32/pthread_rwlock_timedwrlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_timedjoin_np_time32.o: \
  $(srcdir)/compat/time32/pthread_timedjoin_np_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/recvmmsg_time32.o: \
  $(srcdir)/compat/time32/recvmmsg_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sched_rr_get_interval_time32.o: \
  $(srcdir)/compat/time32/sched_rr_get_interval_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/select_time32.o: $(srcdir)/compat/time32/select_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sem_timedwait_time32.o: \
  $(srcdir)/compat/time32/sem_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/semtimedop_time32.o: \
  $(srcdir)/compat/time32/semtimedop_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/setitimer_time32.o: \
  $(srcdir)/compat/time32/setitimer_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/settimeofday_time32.o: \
  $(srcdir)/compat/time32/settimeofday_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sigtimedwait_time32.o: \
  $(srcdir)/compat/time32/sigtimedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/stat_time32.o: $(srcdir)/compat/time32/stat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/stime32.o: $(srcdir)/compat/time32/stime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/thrd_sleep_time32.o: \
  $(srcdir)/compat/time32/thrd_sleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/time32.o: $(srcdir)/compat/time32/time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/time32gm.o: $(srcdir)/compat/time32/time32gm.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timer_gettime32.o: \
  $(srcdir)/compat/time32/timer_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timer_settime32.o: \
  $(srcdir)/compat/time32/timer_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timerfd_gettime32.o: \
  $(srcdir)/compat/time32/timerfd_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timerfd_settime32.o: \
  $(srcdir)/compat/time32/timerfd_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timespec_get_time32.o: \
  $(srcdir)/compat/time32/timespec_get_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utime_time32.o: $(srcdir)/compat/time32/utime_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utimensat_time32.o: \
  $(srcdir)/compat/time32/utimensat_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utimes_time32.o: $(srcdir)/compat/time32/utimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/wait3_time32.o: $(srcdir)/compat/time32/wait3_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/wait4_time32.o: $(srcdir)/compat/time32/wait4_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/Scrt1.o: $(srcdir)/crt/Scrt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crt1.o: $(srcdir)/crt/crt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crti.o: $(srcdir)/crt/crti.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crtn.o: $(srcdir)/crt/crtn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/rcrt1.o: $(srcdir)/crt/rcrt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/ldso/dlstart.o: $(srcdir)/ldso/dlstart.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/ldso/dynlink.o: $(srcdir)/ldso/dynlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/aio.o: $(srcdir)/src/aio/aio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/aio_suspend.o: $(srcdir)/src/aio/aio_suspend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/lio_listio.o: $(srcdir)/src/aio/lio_listio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/__cexp.o: $(srcdir)/src/complex/__cexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/__cexpf.o: $(srcdir)/src/complex/__cexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabs.o: $(srcdir)/src/complex/cabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabsf.o: $(srcdir)/src/complex/cabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabsl.o: $(srcdir)/src/complex/cabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacos.o: $(srcdir)/src/complex/cacos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosf.o: $(srcdir)/src/complex/cacosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosh.o: $(srcdir)/src/complex/cacosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacoshf.o: $(srcdir)/src/complex/cacoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacoshl.o: $(srcdir)/src/complex/cacoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosl.o: $(srcdir)/src/complex/cacosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/carg.o: $(srcdir)/src/complex/carg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cargf.o: $(srcdir)/src/complex/cargf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cargl.o: $(srcdir)/src/complex/cargl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casin.o: $(srcdir)/src/complex/casin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinf.o: $(srcdir)/src/complex/casinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinh.o: $(srcdir)/src/complex/casinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinhf.o: $(srcdir)/src/complex/casinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinhl.o: $(srcdir)/src/complex/casinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinl.o: $(srcdir)/src/complex/casinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catan.o: $(srcdir)/src/complex/catan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanf.o: $(srcdir)/src/complex/catanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanh.o: $(srcdir)/src/complex/catanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanhf.o: $(srcdir)/src/complex/catanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanhl.o: $(srcdir)/src/complex/catanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanl.o: $(srcdir)/src/complex/catanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccos.o: $(srcdir)/src/complex/ccos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosf.o: $(srcdir)/src/complex/ccosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosh.o: $(srcdir)/src/complex/ccosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccoshf.o: $(srcdir)/src/complex/ccoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccoshl.o: $(srcdir)/src/complex/ccoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosl.o: $(srcdir)/src/complex/ccosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexp.o: $(srcdir)/src/complex/cexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexpf.o: $(srcdir)/src/complex/cexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexpl.o: $(srcdir)/src/complex/cexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimag.o: $(srcdir)/src/complex/cimag.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimagf.o: $(srcdir)/src/complex/cimagf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimagl.o: $(srcdir)/src/complex/cimagl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clog.o: $(srcdir)/src/complex/clog.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clogf.o: $(srcdir)/src/complex/clogf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clogl.o: $(srcdir)/src/complex/clogl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conj.o: $(srcdir)/src/complex/conj.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conjf.o: $(srcdir)/src/complex/conjf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conjl.o: $(srcdir)/src/complex/conjl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpow.o: $(srcdir)/src/complex/cpow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpowf.o: $(srcdir)/src/complex/cpowf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpowl.o: $(srcdir)/src/complex/cpowl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cproj.o: $(srcdir)/src/complex/cproj.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cprojf.o: $(srcdir)/src/complex/cprojf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cprojl.o: $(srcdir)/src/complex/cprojl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/creal.o: $(srcdir)/src/complex/creal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/crealf.o: $(srcdir)/src/complex/crealf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/creall.o: $(srcdir)/src/complex/creall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csin.o: $(srcdir)/src/complex/csin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinf.o: $(srcdir)/src/complex/csinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinh.o: $(srcdir)/src/complex/csinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinhf.o: $(srcdir)/src/complex/csinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinhl.o: $(srcdir)/src/complex/csinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinl.o: $(srcdir)/src/complex/csinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrt.o: $(srcdir)/src/complex/csqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrtf.o: $(srcdir)/src/complex/csqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrtl.o: $(srcdir)/src/complex/csqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctan.o: $(srcdir)/src/complex/ctan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanf.o: $(srcdir)/src/complex/ctanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanh.o: $(srcdir)/src/complex/ctanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanhf.o: $(srcdir)/src/complex/ctanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanhl.o: $(srcdir)/src/complex/ctanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanl.o: $(srcdir)/src/complex/ctanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/confstr.o: $(srcdir)/src/conf/confstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/legacy.o: $(srcdir)/src/conf/legacy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/fpathconf.o: $(srcdir)/src/conf/fpathconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/pathconf.o: $(srcdir)/src/conf/pathconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/sysconf.o: $(srcdir)/src/conf/sysconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt.o: $(srcdir)/src/crypt/crypt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_blowfish.o: $(srcdir)/src/crypt/crypt_blowfish.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_des.o: $(srcdir)/src/crypt/crypt_des.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_md5.o: $(srcdir)/src/crypt/crypt_md5.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_r.o: $(srcdir)/src/crypt/crypt_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_sha256.o: $(srcdir)/src/crypt/crypt_sha256.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_sha512.o: $(srcdir)/src/crypt/crypt_sha512.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/encrypt.o: $(srcdir)/src/crypt/encrypt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_b_loc.o: $(srcdir)/src/ctype/__ctype_b_loc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_get_mb_cur_max.o: \
  $(srcdir)/src/ctype/__ctype_get_mb_cur_max.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_tolower_loc.o: \
  $(srcdir)/src/ctype/__ctype_tolower_loc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_toupper_loc.o: \
  $(srcdir)/src/ctype/__ctype_toupper_loc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isalnum.o: $(srcdir)/src/ctype/isalnum.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isalpha.o: $(srcdir)/src/ctype/isalpha.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isascii.o: $(srcdir)/src/ctype/isascii.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isblank.o: $(srcdir)/src/ctype/isblank.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iscntrl.o: $(srcdir)/src/ctype/iscntrl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isdigit.o: $(srcdir)/src/ctype/isdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isgraph.o: $(srcdir)/src/ctype/isgraph.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/islower.o: $(srcdir)/src/ctype/islower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isprint.o: $(srcdir)/src/ctype/isprint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/ispunct.o: $(srcdir)/src/ctype/ispunct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isspace.o: $(srcdir)/src/ctype/isspace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isupper.o: $(srcdir)/src/ctype/isupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswalnum.o: $(srcdir)/src/ctype/iswalnum.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswalpha.o: $(srcdir)/src/ctype/iswalpha.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswblank.o: $(srcdir)/src/ctype/iswblank.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswcntrl.o: $(srcdir)/src/ctype/iswcntrl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswctype.o: $(srcdir)/src/ctype/iswctype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswdigit.o: $(srcdir)/src/ctype/iswdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswgraph.o: $(srcdir)/src/ctype/iswgraph.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswlower.o: $(srcdir)/src/ctype/iswlower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswprint.o: $(srcdir)/src/ctype/iswprint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswpunct.o: $(srcdir)/src/ctype/iswpunct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswspace.o: $(srcdir)/src/ctype/iswspace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswupper.o: $(srcdir)/src/ctype/iswupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswxdigit.o: $(srcdir)/src/ctype/iswxdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isxdigit.o: $(srcdir)/src/ctype/isxdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/toascii.o: $(srcdir)/src/ctype/toascii.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/tolower.o: $(srcdir)/src/ctype/tolower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/toupper.o: $(srcdir)/src/ctype/toupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/towctrans.o: $(srcdir)/src/ctype/towctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wcswidth.o: $(srcdir)/src/ctype/wcswidth.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wctrans.o: $(srcdir)/src/ctype/wctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wcwidth.o: $(srcdir)/src/ctype/wcwidth.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/alphasort.o: $(srcdir)/src/dirent/alphasort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/closedir.o: $(srcdir)/src/dirent/closedir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/dirfd.o: $(srcdir)/src/dirent/dirfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/fdopendir.o: $(srcdir)/src/dirent/fdopendir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/opendir.o: $(srcdir)/src/dirent/opendir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/posix_getdents.o: $(srcdir)/src/dirent/posix_getdents.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/readdir.o: $(srcdir)/src/dirent/readdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/readdir_r.o: $(srcdir)/src/dirent/readdir_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/rewinddir.o: $(srcdir)/src/dirent/rewinddir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/scandir.o: $(srcdir)/src/dirent/scandir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/seekdir.o: $(srcdir)/src/dirent/seekdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/telldir.o: $(srcdir)/src/dirent/telldir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/versionsort.o: $(srcdir)/src/dirent/versionsort.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__environ.o: $(srcdir)/src/env/__environ.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__init_tls.o: $(srcdir)/src/env/__init_tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__libc_start_main.o: $(srcdir)/src/env/__libc_start_main.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__reset_tls.o: $(srcdir)/src/env/__reset_tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__stack_chk_fail.o: $(srcdir)/src/env/__stack_chk_fail.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/clearenv.o: $(srcdir)/src/env/clearenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/getenv.o: $(srcdir)/src/env/getenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/putenv.o: $(srcdir)/src/env/putenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/secure_getenv.o: $(srcdir)/src/env/secure_getenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/setenv.o: $(srcdir)/src/env/setenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/unsetenv.o: $(srcdir)/src/env/unsetenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/errno/__errno_location.o: $(srcdir)/src/errno/__errno_location.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/errno/strerror.o: $(srcdir)/src/errno/strerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/arm/__aeabi_atexit.o: $(srcdir)/src/exit/arm/__aeabi_atexit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/_Exit.o: $(srcdir)/src/exit/_Exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/abort.o: $(srcdir)/src/exit/abort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/abort_lock.o: $(srcdir)/src/exit/abort_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/assert.o: $(srcdir)/src/exit/assert.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/at_quick_exit.o: $(srcdir)/src/exit/at_quick_exit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/atexit.o: $(srcdir)/src/exit/atexit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/exit.o: $(srcdir)/src/exit/exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/quick_exit.o: $(srcdir)/src/exit/quick_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/creat.o: $(srcdir)/src/fcntl/creat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/fcntl.o: $(srcdir)/src/fcntl/fcntl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/open.o: $(srcdir)/src/fcntl/open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/openat.o: $(srcdir)/src/fcntl/openat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/posix_fadvise.o: $(srcdir)/src/fcntl/posix_fadvise.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/posix_fallocate.o: $(srcdir)/src/fcntl/posix_fallocate.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/__flt_rounds.o: $(srcdir)/src/fenv/__flt_rounds.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fegetexceptflag.o: $(srcdir)/src/fenv/fegetexceptflag.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/feholdexcept.o: $(srcdir)/src/fenv/feholdexcept.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fenv.o: $(srcdir)/src/fenv/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/arm/fenv.o: $(srcdir)/src/fenv/arm/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/m68k/fenv.o: $(srcdir)/src/fenv/m68k/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips/fenv-sf.o: $(srcdir)/src/fenv/mips/fenv-sf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips64/fenv-sf.o: $(srcdir)/src/fenv/mips64/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mipsn32/fenv-sf.o: $(srcdir)/src/fenv/mipsn32/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc/fenv-sf.o: $(srcdir)/src/fenv/powerpc/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc64/fenv.o: $(srcdir)/src/fenv/powerpc64/fenv.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv32/fenv-sf.o: $(srcdir)/src/fenv/riscv32/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv64/fenv-sf.o: $(srcdir)/src/fenv/riscv64/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/s390x/fenv.o: $(srcdir)/src/fenv/s390x/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/sh/fenv-nofpu.o: $(srcdir)/src/fenv/sh/fenv-nofpu.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fesetexceptflag.o: $(srcdir)/src/fenv/fesetexceptflag.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fesetround.o: $(srcdir)/src/fenv/fesetround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/feupdateenv.o: $(srcdir)/src/fenv/feupdateenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/sh/__shcall.o: $(srcdir)/src/internal/sh/__shcall.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/defsysinfo.o: $(srcdir)/src/internal/defsysinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/emulate_wait4.o: $(srcdir)/src/internal/emulate_wait4.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/floatscan.o: $(srcdir)/src/internal/floatscan.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/intscan.o: $(srcdir)/src/internal/intscan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/libc.o: $(srcdir)/src/internal/libc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/procfdname.o: $(srcdir)/src/internal/procfdname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/shgetc.o: $(srcdir)/src/internal/shgetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/syscall_ret.o: $(srcdir)/src/internal/syscall_ret.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/version.o: $(srcdir)/src/internal/version.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/vdso.o: $(srcdir)/src/internal/vdso.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/ftok.o: $(srcdir)/src/ipc/ftok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgctl.o: $(srcdir)/src/ipc/msgctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgget.o: $(srcdir)/src/ipc/msgget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgrcv.o: $(srcdir)/src/ipc/msgrcv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgsnd.o: $(srcdir)/src/ipc/msgsnd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semctl.o: $(srcdir)/src/ipc/semctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semget.o: $(srcdir)/src/ipc/semget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semop.o: $(srcdir)/src/ipc/semop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semtimedop.o: $(srcdir)/src/ipc/semtimedop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmat.o: $(srcdir)/src/ipc/shmat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmctl.o: $(srcdir)/src/ipc/shmctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmdt.o: $(srcdir)/src/ipc/shmdt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmget.o: $(srcdir)/src/ipc/shmget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/__dlsym.o: $(srcdir)/src/ldso/__dlsym.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dl_iterate_phdr.o: $(srcdir)/src/ldso/dl_iterate_phdr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dladdr.o: $(srcdir)/src/ldso/dladdr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlclose.o: $(srcdir)/src/ldso/dlclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlerror.o: $(srcdir)/src/ldso/dlerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlinfo.o: $(srcdir)/src/ldso/dlinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlopen.o: $(srcdir)/src/ldso/dlopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlsym.o: $(srcdir)/src/ldso/dlsym.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/find_exidx.o: $(srcdir)/src/ldso/arm/find_exidx.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/tlsdesc.o: $(srcdir)/src/ldso/tlsdesc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/cuserid.o: $(srcdir)/src/legacy/cuserid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/daemon.o: $(srcdir)/src/legacy/daemon.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/err.o: $(srcdir)/src/legacy/err.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/euidaccess.o: $(srcdir)/src/legacy/euidaccess.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/ftw.o: $(srcdir)/src/legacy/ftw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/futimes.o: $(srcdir)/src/legacy/futimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getdtablesize.o: $(srcdir)/src/legacy/getdtablesize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getloadavg.o: $(srcdir)/src/legacy/getloadavg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getpagesize.o: $(srcdir)/src/legacy/getpagesize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getpass.o: $(srcdir)/src/legacy/getpass.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getusershell.o: $(srcdir)/src/legacy/getusershell.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/isastream.o: $(srcdir)/src/legacy/isastream.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/lutimes.o: $(srcdir)/src/legacy/lutimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/ulimit.o: $(srcdir)/src/legacy/ulimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/utmpx.o: $(srcdir)/src/legacy/utmpx.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/valloc.o: $(srcdir)/src/legacy/valloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/adjtime.o: $(srcdir)/src/linux/adjtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/adjtimex.o: $(srcdir)/src/linux/adjtimex.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/arch_prctl.o: $(srcdir)/src/linux/arch_prctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/brk.o: $(srcdir)/src/linux/brk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/cache.o: $(srcdir)/src/linux/cache.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/cap.o: $(srcdir)/src/linux/cap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/chroot.o: $(srcdir)/src/linux/chroot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/clock_adjtime.o: $(srcdir)/src/linux/clock_adjtime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/clone.o: $(srcdir)/src/linux/clone.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/copy_file_range.o: $(srcdir)/src/linux/copy_file_range.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/epoll.o: $(srcdir)/src/linux/epoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/eventfd.o: $(srcdir)/src/linux/eventfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/fallocate.o: $(srcdir)/src/linux/fallocate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/fanotify.o: $(srcdir)/src/linux/fanotify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/flock.o: $(srcdir)/src/linux/flock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/getdents.o: $(srcdir)/src/linux/getdents.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/getrandom.o: $(srcdir)/src/linux/getrandom.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/gettid.o: $(srcdir)/src/linux/gettid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/inotify.o: $(srcdir)/src/linux/inotify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/ioperm.o: $(srcdir)/src/linux/ioperm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/iopl.o: $(srcdir)/src/linux/iopl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/klogctl.o: $(srcdir)/src/linux/klogctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/membarrier.o: $(srcdir)/src/linux/membarrier.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/memfd_create.o: $(srcdir)/src/linux/memfd_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/mlock2.o: $(srcdir)/src/linux/mlock2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/module.o: $(srcdir)/src/linux/module.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/mount.o: $(srcdir)/src/linux/mount.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/name_to_handle_at.o: $(srcdir)/src/linux/name_to_handle_at.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/open_by_handle_at.o: $(srcdir)/src/linux/open_by_handle_at.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/personality.o: $(srcdir)/src/linux/personality.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/pivot_root.o: $(srcdir)/src/linux/pivot_root.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/prctl.o: $(srcdir)/src/linux/prctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/preadv2.o: $(srcdir)/src/linux/preadv2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/prlimit.o: $(srcdir)/src/linux/prlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/process_vm.o: $(srcdir)/src/linux/process_vm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/ptrace.o: $(srcdir)/src/linux/ptrace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/pwritev2.o: $(srcdir)/src/linux/pwritev2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/quotactl.o: $(srcdir)/src/linux/quotactl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/readahead.o: $(srcdir)/src/linux/readahead.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/reboot.o: $(srcdir)/src/linux/reboot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/remap_file_pages.o: $(srcdir)/src/linux/remap_file_pages.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/renameat2.o: $(srcdir)/src/linux/renameat2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sbrk.o: $(srcdir)/src/linux/sbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sendfile.o: $(srcdir)/src/linux/sendfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setfsgid.o: $(srcdir)/src/linux/setfsgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setfsuid.o: $(srcdir)/src/linux/setfsuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setgroups.o: $(srcdir)/src/linux/setgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sethostname.o: $(srcdir)/src/linux/sethostname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setns.o: $(srcdir)/src/linux/setns.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/settimeofday.o: $(srcdir)/src/linux/settimeofday.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/signalfd.o: $(srcdir)/src/linux/signalfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/splice.o: $(srcdir)/src/linux/splice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/statx.o: $(srcdir)/src/linux/statx.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/stime.o: $(srcdir)/src/linux/stime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/swap.o: $(srcdir)/src/linux/swap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sync_file_range.o: $(srcdir)/src/linux/sync_file_range.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/syncfs.o: $(srcdir)/src/linux/syncfs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sysinfo.o: $(srcdir)/src/linux/sysinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/x32/sysinfo.o: $(srcdir)/src/linux/x32/sysinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/tee.o: $(srcdir)/src/linux/tee.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/timerfd.o: $(srcdir)/src/linux/timerfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/unshare.o: $(srcdir)/src/linux/unshare.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/utimes.o: $(srcdir)/src/linux/utimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/vhangup.o: $(srcdir)/src/linux/vhangup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/vmsplice.o: $(srcdir)/src/linux/vmsplice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/wait3.o: $(srcdir)/src/linux/wait3.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/wait4.o: $(srcdir)/src/linux/wait4.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/xattr.o: $(srcdir)/src/linux/xattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/__lctrans.o: $(srcdir)/src/locale/__lctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/__mo_lookup.o: $(srcdir)/src/locale/__mo_lookup.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/bind_textdomain_codeset.o: \
  $(srcdir)/src/locale/bind_textdomain_codeset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/c_locale.o: $(srcdir)/src/locale/c_locale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catclose.o: $(srcdir)/src/locale/catclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catgets.o: $(srcdir)/src/locale/catgets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catopen.o: $(srcdir)/src/locale/catopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/dcngettext.o: $(srcdir)/src/locale/dcngettext.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/duplocale.o: $(srcdir)/src/locale/duplocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/freelocale.o: $(srcdir)/src/locale/freelocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/iconv.o: $(srcdir)/src/locale/iconv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/iconv_close.o: $(srcdir)/src/locale/iconv_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/langinfo.o: $(srcdir)/src/locale/langinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/locale_map.o: $(srcdir)/src/locale/locale_map.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/localeconv.o: $(srcdir)/src/locale/localeconv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/newlocale.o: $(srcdir)/src/locale/newlocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/pleval.o: $(srcdir)/src/locale/pleval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/setlocale.o: $(srcdir)/src/locale/setlocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strcoll.o: $(srcdir)/src/locale/strcoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strfmon.o: $(srcdir)/src/locale/strfmon.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strtod_l.o: $(srcdir)/src/locale/strtod_l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strxfrm.o: $(srcdir)/src/locale/strxfrm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/textdomain.o: $(srcdir)/src/locale/textdomain.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/uselocale.o: $(srcdir)/src/locale/uselocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/wcscoll.o: $(srcdir)/src/locale/wcscoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/wcsxfrm.o: $(srcdir)/src/locale/wcsxfrm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/calloc.o: $(srcdir)/src/malloc/calloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/free.o: $(srcdir)/src/malloc/free.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/libc_calloc.o: $(srcdir)/src/malloc/libc_calloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/lite_malloc.o: $(srcdir)/src/malloc/lite_malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/aligned_alloc.o: \
  $(srcdir)/src/malloc/mallocng/aligned_alloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/donate.o: $(srcdir)/src/malloc/mallocng/donate.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/free.o: $(srcdir)/src/malloc/mallocng/free.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/malloc.o: $(srcdir)/src/malloc/mallocng/malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/malloc_usable_size.o: \
  $(srcdir)/src/malloc/mallocng/malloc_usable_size.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/realloc.o: $(srcdir)/src/malloc/mallocng/realloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/memalign.o: $(srcdir)/src/malloc/memalign.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/aligned_alloc.o: \
  $(srcdir)/src/malloc/oldmalloc/aligned_alloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/malloc.o: $(srcdir)/src/malloc/oldmalloc/malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/malloc_usable_size.o: \
  $(srcdir)/src/malloc/oldmalloc/malloc_usable_size.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/posix_memalign.o: $(srcdir)/src/malloc/posix_memalign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/realloc.o: $(srcdir)/src/malloc/realloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/reallocarray.o: $(srcdir)/src/malloc/reallocarray.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/replaced.o: $(srcdir)/src/malloc/replaced.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cos.o: $(srcdir)/src/math/__cos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cosdf.o: $(srcdir)/src/math/__cosdf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cosl.o: $(srcdir)/src/math/__cosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__expo2.o: $(srcdir)/src/math/__expo2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__expo2f.o: $(srcdir)/src/math/__expo2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassify.o: $(srcdir)/src/math/__fpclassify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassifyf.o: $(srcdir)/src/math/__fpclassifyf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassifyl.o: $(srcdir)/src/math/__fpclassifyl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__invtrigl.o: $(srcdir)/src/math/__invtrigl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_divzero.o: $(srcdir)/src/math/__math_divzero.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_divzerof.o: $(srcdir)/src/math/__math_divzerof.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalid.o: $(srcdir)/src/math/__math_invalid.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalidf.o: $(srcdir)/src/math/__math_invalidf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalidl.o: $(srcdir)/src/math/__math_invalidl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_oflow.o: $(srcdir)/src/math/__math_oflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_oflowf.o: $(srcdir)/src/math/__math_oflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_uflow.o: $(srcdir)/src/math/__math_uflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_uflowf.o: $(srcdir)/src/math/__math_uflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_xflow.o: $(srcdir)/src/math/__math_xflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_xflowf.o: $(srcdir)/src/math/__math_xflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__polevll.o: $(srcdir)/src/math/__polevll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2.o: $(srcdir)/src/math/__rem_pio2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2_large.o: $(srcdir)/src/math/__rem_pio2_large.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2f.o: $(srcdir)/src/math/__rem_pio2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2l.o: $(srcdir)/src/math/__rem_pio2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbit.o: $(srcdir)/src/math/__signbit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbitf.o: $(srcdir)/src/math/__signbitf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbitl.o: $(srcdir)/src/math/__signbitl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sin.o: $(srcdir)/src/math/__sin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sindf.o: $(srcdir)/src/math/__sindf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sinl.o: $(srcdir)/src/math/__sinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tan.o: $(srcdir)/src/math/__tan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tandf.o: $(srcdir)/src/math/__tandf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tanl.o: $(srcdir)/src/math/__tanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acos.o: $(srcdir)/src/math/acos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosf.o: $(srcdir)/src/math/acosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosh.o: $(srcdir)/src/math/acosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acoshf.o: $(srcdir)/src/math/acoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acoshl.o: $(srcdir)/src/math/acoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosl.o: $(srcdir)/src/math/acosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asin.o: $(srcdir)/src/math/asin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinf.o: $(srcdir)/src/math/asinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinh.o: $(srcdir)/src/math/asinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinhf.o: $(srcdir)/src/math/asinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinhl.o: $(srcdir)/src/math/asinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinl.o: $(srcdir)/src/math/asinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan.o: $(srcdir)/src/math/atan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2.o: $(srcdir)/src/math/atan2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2f.o: $(srcdir)/src/math/atan2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2l.o: $(srcdir)/src/math/atan2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanf.o: $(srcdir)/src/math/atanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanh.o: $(srcdir)/src/math/atanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanhf.o: $(srcdir)/src/math/atanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanhl.o: $(srcdir)/src/math/atanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanl.o: $(srcdir)/src/math/atanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrt.o: $(srcdir)/src/math/cbrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrtf.o: $(srcdir)/src/math/cbrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrtl.o: $(srcdir)/src/math/cbrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceil.o: $(srcdir)/src/math/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/ceil.o: $(srcdir)/src/math/aarch64/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/ceil.o: $(srcdir)/src/math/powerpc64/ceil.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceil.o: $(srcdir)/src/math/s390x/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceilf.o: $(srcdir)/src/math/ceilf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/ceilf.o: $(srcdir)/src/math/aarch64/ceilf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/ceilf.o: $(srcdir)/src/math/powerpc64/ceilf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceilf.o: $(srcdir)/src/math/s390x/ceilf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceill.o: $(srcdir)/src/math/ceill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceill.o: $(srcdir)/src/math/s390x/ceill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysign.o: $(srcdir)/src/math/copysign.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/copysign.o: $(srcdir)/src/math/riscv32/copysign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/copysign.o: $(srcdir)/src/math/riscv64/copysign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysignf.o: $(srcdir)/src/math/copysignf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/copysignf.o: $(srcdir)/src/math/riscv32/copysignf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/copysignf.o: $(srcdir)/src/math/riscv64/copysignf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysignl.o: $(srcdir)/src/math/copysignl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cos.o: $(srcdir)/src/math/cos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosf.o: $(srcdir)/src/math/cosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosh.o: $(srcdir)/src/math/cosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/coshf.o: $(srcdir)/src/math/coshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/coshl.o: $(srcdir)/src/math/coshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosl.o: $(srcdir)/src/math/cosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erf.o: $(srcdir)/src/math/erf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erff.o: $(srcdir)/src/math/erff.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erfl.o: $(srcdir)/src/math/erfl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp.o: $(srcdir)/src/math/exp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp_data.o: $(srcdir)/src/math/exp_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10.o: $(srcdir)/src/math/exp10.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10f.o: $(srcdir)/src/math/exp10f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10l.o: $(srcdir)/src/math/exp10l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2.o: $(srcdir)/src/math/exp2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2f.o: $(srcdir)/src/math/exp2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2f_data.o: $(srcdir)/src/math/exp2f_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2l.o: $(srcdir)/src/math/exp2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expf.o: $(srcdir)/src/math/expf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expl.o: $(srcdir)/src/math/expl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1.o: $(srcdir)/src/math/expm1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1f.o: $(srcdir)/src/math/expm1f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1l.o: $(srcdir)/src/math/expm1l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabs.o: $(srcdir)/src/math/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fabs.o: $(srcdir)/src/math/aarch64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fabs.o: $(srcdir)/src/math/arm/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabs.o: $(srcdir)/src/math/i386/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/fabs.o: $(srcdir)/src/math/mips/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fabs.o: $(srcdir)/src/math/powerpc/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fabs.o: $(srcdir)/src/math/powerpc64/fabs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fabs.o: $(srcdir)/src/math/riscv32/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fabs.o: $(srcdir)/src/math/riscv64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabs.o: $(srcdir)/src/math/s390x/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabs.o: $(srcdir)/src/math/x86_64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabsf.o: $(srcdir)/src/math/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fabsf.o: $(srcdir)/src/math/aarch64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fabsf.o: $(srcdir)/src/math/arm/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabsf.o: $(srcdir)/src/math/i386/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/fabsf.o: $(srcdir)/src/math/mips/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fabsf.o: $(srcdir)/src/math/powerpc/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fabsf.o: $(srcdir)/src/math/powerpc64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fabsf.o: $(srcdir)/src/math/riscv32/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fabsf.o: $(srcdir)/src/math/riscv64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabsf.o: $(srcdir)/src/math/s390x/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabsf.o: $(srcdir)/src/math/x86_64/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabsl.o: $(srcdir)/src/math/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabsl.o: $(srcdir)/src/math/i386/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabsl.o: $(srcdir)/src/math/s390x/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabsl.o: $(srcdir)/src/math/x86_64/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdim.o: $(srcdir)/src/math/fdim.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdimf.o: $(srcdir)/src/math/fdimf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdiml.o: $(srcdir)/src/math/fdiml.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/finite.o: $(srcdir)/src/math/finite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/finitef.o: $(srcdir)/src/math/finitef.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floor.o: $(srcdir)/src/math/floor.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/floor.o: $(srcdir)/src/math/aarch64/floor.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/floor.o: $(srcdir)/src/math/powerpc64/floor.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floor.o: $(srcdir)/src/math/s390x/floor.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floorf.o: $(srcdir)/src/math/floorf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/floorf.o: $(srcdir)/src/math/aarch64/floorf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/floorf.o: $(srcdir)/src/math/powerpc64/floorf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floorf.o: $(srcdir)/src/math/s390x/floorf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floorl.o: $(srcdir)/src/math/floorl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floorl.o: $(srcdir)/src/math/s390x/floorl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fma.o: $(srcdir)/src/math/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fma.o: $(srcdir)/src/math/aarch64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fma.o: $(srcdir)/src/math/arm/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fma.o: $(srcdir)/src/math/powerpc/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fma.o: $(srcdir)/src/math/powerpc64/fma.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fma.o: $(srcdir)/src/math/riscv32/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fma.o: $(srcdir)/src/math/riscv64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fma.o: $(srcdir)/src/math/s390x/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x32/fma.o: $(srcdir)/src/math/x32/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fma.o: $(srcdir)/src/math/x86_64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaf.o: $(srcdir)/src/math/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmaf.o: $(srcdir)/src/math/aarch64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fmaf.o: $(srcdir)/src/math/arm/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fmaf.o: $(srcdir)/src/math/powerpc/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmaf.o: $(srcdir)/src/math/powerpc64/fmaf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmaf.o: $(srcdir)/src/math/riscv32/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmaf.o: $(srcdir)/src/math/riscv64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fmaf.o: $(srcdir)/src/math/s390x/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x32/fmaf.o: $(srcdir)/src/math/x32/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fmaf.o: $(srcdir)/src/math/x86_64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmal.o: $(srcdir)/src/math/fmal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmax.o: $(srcdir)/src/math/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmax.o: $(srcdir)/src/math/aarch64/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmax.o: $(srcdir)/src/math/powerpc64/fmax.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmax.o: $(srcdir)/src/math/riscv32/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmax.o: $(srcdir)/src/math/riscv64/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaxf.o: $(srcdir)/src/math/fmaxf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmaxf.o: $(srcdir)/src/math/aarch64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmaxf.o: $(srcdir)/src/math/powerpc64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmaxf.o: $(srcdir)/src/math/riscv32/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmaxf.o: $(srcdir)/src/math/riscv64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaxl.o: $(srcdir)/src/math/fmaxl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmin.o: $(srcdir)/src/math/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmin.o: $(srcdir)/src/math/aarch64/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmin.o: $(srcdir)/src/math/powerpc64/fmin.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmin.o: $(srcdir)/src/math/riscv32/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmin.o: $(srcdir)/src/math/riscv64/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fminf.o: $(srcdir)/src/math/fminf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fminf.o: $(srcdir)/src/math/aarch64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fminf.o: $(srcdir)/src/math/powerpc64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fminf.o: $(srcdir)/src/math/riscv32/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fminf.o: $(srcdir)/src/math/riscv64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fminl.o: $(srcdir)/src/math/fminl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmod.o: $(srcdir)/src/math/fmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmod.o: $(srcdir)/src/math/i386/fmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmodf.o: $(srcdir)/src/math/fmodf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmodf.o: $(srcdir)/src/math/i386/fmodf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmodl.o: $(srcdir)/src/math/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmodl.o: $(srcdir)/src/math/i386/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fmodl.o: $(srcdir)/src/math/x86_64/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexp.o: $(srcdir)/src/math/frexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexpf.o: $(srcdir)/src/math/frexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexpl.o: $(srcdir)/src/math/frexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypot.o: $(srcdir)/src/math/hypot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypotf.o: $(srcdir)/src/math/hypotf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypotl.o: $(srcdir)/src/math/hypotl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogb.o: $(srcdir)/src/math/ilogb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogbf.o: $(srcdir)/src/math/ilogbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogbl.o: $(srcdir)/src/math/ilogbl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j0.o: $(srcdir)/src/math/j0.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j0f.o: $(srcdir)/src/math/j0f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j1.o: $(srcdir)/src/math/j1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j1f.o: $(srcdir)/src/math/j1f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/jn.o: $(srcdir)/src/math/jn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/jnf.o: $(srcdir)/src/math/jnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexp.o: $(srcdir)/src/math/ldexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexpf.o: $(srcdir)/src/math/ldexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexpl.o: $(srcdir)/src/math/ldexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgamma.o: $(srcdir)/src/math/lgamma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgamma_r.o: $(srcdir)/src/math/lgamma_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammaf.o: $(srcdir)/src/math/lgammaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammaf_r.o: $(srcdir)/src/math/lgammaf_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammal.o: $(srcdir)/src/math/lgammal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrint.o: $(srcdir)/src/math/llrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llrint.o: $(srcdir)/src/math/aarch64/llrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrint.o: $(srcdir)/src/math/i386/llrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrint.o: $(srcdir)/src/math/x86_64/llrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrintf.o: $(srcdir)/src/math/llrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llrintf.o: $(srcdir)/src/math/aarch64/llrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrintf.o: $(srcdir)/src/math/i386/llrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrintf.o: $(srcdir)/src/math/x86_64/llrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrintl.o: $(srcdir)/src/math/llrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrintl.o: $(srcdir)/src/math/i386/llrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrintl.o: $(srcdir)/src/math/x86_64/llrintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llround.o: $(srcdir)/src/math/llround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llround.o: $(srcdir)/src/math/aarch64/llround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llroundf.o: $(srcdir)/src/math/llroundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llroundf.o: $(srcdir)/src/math/aarch64/llroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llroundl.o: $(srcdir)/src/math/llroundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log.o: $(srcdir)/src/math/log.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10.o: $(srcdir)/src/math/log10.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10f.o: $(srcdir)/src/math/log10f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10l.o: $(srcdir)/src/math/log10l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1p.o: $(srcdir)/src/math/log1p.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1pf.o: $(srcdir)/src/math/log1pf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1pl.o: $(srcdir)/src/math/log1pl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2.o: $(srcdir)/src/math/log2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2_data.o: $(srcdir)/src/math/log2_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2f.o: $(srcdir)/src/math/log2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2f_data.o: $(srcdir)/src/math/log2f_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2l.o: $(srcdir)/src/math/log2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log_data.o: $(srcdir)/src/math/log_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logb.o: $(srcdir)/src/math/logb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logbf.o: $(srcdir)/src/math/logbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logbl.o: $(srcdir)/src/math/logbl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logf.o: $(srcdir)/src/math/logf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logf_data.o: $(srcdir)/src/math/logf_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logl.o: $(srcdir)/src/math/logl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrint.o: $(srcdir)/src/math/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lrint.o: $(srcdir)/src/math/aarch64/lrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrint.o: $(srcdir)/src/math/i386/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lrint.o: $(srcdir)/src/math/powerpc64/lrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrint.o: $(srcdir)/src/math/x86_64/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrintf.o: $(srcdir)/src/math/lrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lrintf.o: $(srcdir)/src/math/aarch64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrintf.o: $(srcdir)/src/math/i386/lrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lrintf.o: $(srcdir)/src/math/powerpc64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrintf.o: $(srcdir)/src/math/x86_64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrintl.o: $(srcdir)/src/math/lrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrintl.o: $(srcdir)/src/math/i386/lrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrintl.o: $(srcdir)/src/math/x86_64/lrintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lround.o: $(srcdir)/src/math/lround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lround.o: $(srcdir)/src/math/aarch64/lround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lround.o: $(srcdir)/src/math/powerpc64/lround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lroundf.o: $(srcdir)/src/math/lroundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lroundf.o: $(srcdir)/src/math/aarch64/lroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lroundf.o: $(srcdir)/src/math/powerpc64/lroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lroundl.o: $(srcdir)/src/math/lroundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modf.o: $(srcdir)/src/math/modf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modff.o: $(srcdir)/src/math/modff.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modfl.o: $(srcdir)/src/math/modfl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nan.o: $(srcdir)/src/math/nan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nanf.o: $(srcdir)/src/math/nanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nanl.o: $(srcdir)/src/math/nanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyint.o: $(srcdir)/src/math/nearbyint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/nearbyint.o: $(srcdir)/src/math/aarch64/nearbyint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyint.o: $(srcdir)/src/math/s390x/nearbyint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyintf.o: $(srcdir)/src/math/nearbyintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/nearbyintf.o: $(srcdir)/src/math/aarch64/nearbyintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyintf.o: $(srcdir)/src/math/s390x/nearbyintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyintl.o: $(srcdir)/src/math/nearbyintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyintl.o: $(srcdir)/src/math/s390x/nearbyintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafter.o: $(srcdir)/src/math/nextafter.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafterf.o: $(srcdir)/src/math/nextafterf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafterl.o: $(srcdir)/src/math/nextafterl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttoward.o: $(srcdir)/src/math/nexttoward.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttowardf.o: $(srcdir)/src/math/nexttowardf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttowardl.o: $(srcdir)/src/math/nexttowardl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/pow.o: $(srcdir)/src/math/pow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/pow_data.o: $(srcdir)/src/math/pow_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powf.o: $(srcdir)/src/math/powf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powf_data.o: $(srcdir)/src/math/powf_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powl.o: $(srcdir)/src/math/powl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainder.o: $(srcdir)/src/math/remainder.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainder.o: $(srcdir)/src/math/i386/remainder.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainderf.o: $(srcdir)/src/math/remainderf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainderf.o: $(srcdir)/src/math/i386/remainderf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainderl.o: $(srcdir)/src/math/remainderl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainderl.o: $(srcdir)/src/math/i386/remainderl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/remainderl.o: $(srcdir)/src/math/x86_64/remainderl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquo.o: $(srcdir)/src/math/remquo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquof.o: $(srcdir)/src/math/remquof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquol.o: $(srcdir)/src/math/remquol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/remquol.o: $(srcdir)/src/math/x86_64/remquol.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rint.o: $(srcdir)/src/math/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/rint.o: $(srcdir)/src/math/aarch64/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rint.o: $(srcdir)/src/math/i386/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rint.o: $(srcdir)/src/math/s390x/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rintf.o: $(srcdir)/src/math/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/rintf.o: $(srcdir)/src/math/aarch64/rintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rintf.o: $(srcdir)/src/math/i386/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rintf.o: $(srcdir)/src/math/s390x/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rintl.o: $(srcdir)/src/math/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rintl.o: $(srcdir)/src/math/i386/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rintl.o: $(srcdir)/src/math/s390x/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/rintl.o: $(srcdir)/src/math/x86_64/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/round.o: $(srcdir)/src/math/round.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/round.o: $(srcdir)/src/math/aarch64/round.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/round.o: $(srcdir)/src/math/powerpc64/round.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/round.o: $(srcdir)/src/math/s390x/round.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/roundf.o: $(srcdir)/src/math/roundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/roundf.o: $(srcdir)/src/math/aarch64/roundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/roundf.o: $(srcdir)/src/math/powerpc64/roundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/roundf.o: $(srcdir)/src/math/s390x/roundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/roundl.o: $(srcdir)/src/math/roundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/roundl.o: $(srcdir)/src/math/s390x/roundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalb.o: $(srcdir)/src/math/scalb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbf.o: $(srcdir)/src/math/scalbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbln.o: $(srcdir)/src/math/scalbln.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalblnf.o: $(srcdir)/src/math/scalblnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalblnl.o: $(srcdir)/src/math/scalblnl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbn.o: $(srcdir)/src/math/scalbn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbnf.o: $(srcdir)/src/math/scalbnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbnl.o: $(srcdir)/src/math/scalbnl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/signgam.o: $(srcdir)/src/math/signgam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/significand.o: $(srcdir)/src/math/significand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/significandf.o: $(srcdir)/src/math/significandf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sin.o: $(srcdir)/src/math/sin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincos.o: $(srcdir)/src/math/sincos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincosf.o: $(srcdir)/src/math/sincosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincosl.o: $(srcdir)/src/math/sincosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinf.o: $(srcdir)/src/math/sinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinh.o: $(srcdir)/src/math/sinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinhf.o: $(srcdir)/src/math/sinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinhl.o: $(srcdir)/src/math/sinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinl.o: $(srcdir)/src/math/sinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrt.o: $(srcdir)/src/math/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/sqrt.o: $(srcdir)/src/math/aarch64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/sqrt.o: $(srcdir)/src/math/arm/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrt.o: $(srcdir)/src/math/i386/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/sqrt.o: $(srcdir)/src/math/mips/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/sqrt.o: $(srcdir)/src/math/powerpc/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/sqrt.o: $(srcdir)/src/math/powerpc64/sqrt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/sqrt.o: $(srcdir)/src/math/riscv32/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/sqrt.o: $(srcdir)/src/math/riscv64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrt.o: $(srcdir)/src/math/s390x/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrt.o: $(srcdir)/src/math/x86_64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrt_data.o: $(srcdir)/src/math/sqrt_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrtf.o: $(srcdir)/src/math/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/sqrtf.o: $(srcdir)/src/math/aarch64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/sqrtf.o: $(srcdir)/src/math/arm/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrtf.o: $(srcdir)/src/math/i386/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/sqrtf.o: $(srcdir)/src/math/mips/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/sqrtf.o: $(srcdir)/src/math/powerpc/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/sqrtf.o: $(srcdir)/src/math/powerpc64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/sqrtf.o: $(srcdir)/src/math/riscv32/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/sqrtf.o: $(srcdir)/src/math/riscv64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrtf.o: $(srcdir)/src/math/s390x/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrtf.o: $(srcdir)/src/math/x86_64/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrtl.o: $(srcdir)/src/math/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrtl.o: $(srcdir)/src/math/i386/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/m68k/sqrtl.o: $(srcdir)/src/math/m68k/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrtl.o: $(srcdir)/src/math/s390x/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrtl.o: $(srcdir)/src/math/x86_64/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tan.o: $(srcdir)/src/math/tan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanf.o: $(srcdir)/src/math/tanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanh.o: $(srcdir)/src/math/tanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanhf.o: $(srcdir)/src/math/tanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanhl.o: $(srcdir)/src/math/tanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanl.o: $(srcdir)/src/math/tanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgamma.o: $(srcdir)/src/math/tgamma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgammaf.o: $(srcdir)/src/math/tgammaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgammal.o: $(srcdir)/src/math/tgammal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/trunc.o: $(srcdir)/src/math/trunc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/trunc.o: $(srcdir)/src/math/aarch64/trunc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/trunc.o: $(srcdir)/src/math/powerpc64/trunc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/trunc.o: $(srcdir)/src/math/s390x/trunc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/truncf.o: $(srcdir)/src/math/truncf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/truncf.o: $(srcdir)/src/math/aarch64/truncf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/truncf.o: $(srcdir)/src/math/powerpc64/truncf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/truncf.o: $(srcdir)/src/math/s390x/truncf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/truncl.o: $(srcdir)/src/math/truncl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/truncl.o: $(srcdir)/src/math/s390x/truncl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/a64l.o: $(srcdir)/src/misc/a64l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/basename.o: $(srcdir)/src/misc/basename.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/dirname.o: $(srcdir)/src/misc/dirname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffs.o: $(srcdir)/src/misc/ffs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffsl.o: $(srcdir)/src/misc/ffsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffsll.o: $(srcdir)/src/misc/ffsll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/fmtmsg.o: $(srcdir)/src/misc/fmtmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/forkpty.o: $(srcdir)/src/misc/forkpty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/get_current_dir_name.o: \
  $(srcdir)/src/misc/get_current_dir_name.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getauxval.o: $(srcdir)/src/misc/getauxval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getdomainname.o: $(srcdir)/src/misc/getdomainname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getentropy.o: $(srcdir)/src/misc/getentropy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/gethostid.o: $(srcdir)/src/misc/gethostid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getopt.o: $(srcdir)/src/misc/getopt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getopt_long.o: $(srcdir)/src/misc/getopt_long.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getpriority.o: $(srcdir)/src/misc/getpriority.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getresgid.o: $(srcdir)/src/misc/getresgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getresuid.o: $(srcdir)/src/misc/getresuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getrlimit.o: $(srcdir)/src/misc/getrlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getrusage.o: $(srcdir)/src/misc/getrusage.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getsubopt.o: $(srcdir)/src/misc/getsubopt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/initgroups.o: $(srcdir)/src/misc/initgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ioctl.o: $(srcdir)/src/misc/ioctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/issetugid.o: $(srcdir)/src/misc/issetugid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/lockf.o: $(srcdir)/src/misc/lockf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/login_tty.o: $(srcdir)/src/misc/login_tty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/mntent.o: $(srcdir)/src/misc/mntent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/nftw.o: $(srcdir)/src/misc/nftw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ptsname.o: $(srcdir)/src/misc/ptsname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setpriority.o: $(srcdir)/src/misc/setpriority.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/syscall.o: $(srcdir)/src/misc/syscall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/syslog.o: $(srcdir)/src/misc/syslog.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/openpty.o: $(srcdir)/src/misc/openpty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/pty.o: $(srcdir)/src/misc/pty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/realpath.o: $(srcdir)/src/misc/realpath.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setdomainname.o: $(srcdir)/src/misc/setdomainname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setrlimit.o: $(srcdir)/src/misc/setrlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/uname.o: $(srcdir)/src/misc/uname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/wordexp.o: $(srcdir)/src/misc/wordexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/madvise.o: $(srcdir)/src/mman/madvise.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mincore.o: $(srcdir)/src/mman/mincore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mlock.o: $(srcdir)/src/mman/mlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mlockall.o: $(srcdir)/src/mman/mlockall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mmap.o: $(srcdir)/src/mman/mmap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mprotect.o: $(srcdir)/src/mman/mprotect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mremap.o: $(srcdir)/src/mman/mremap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/msync.o: $(srcdir)/src/mman/msync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munlock.o: $(srcdir)/src/mman/munlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munlockall.o: $(srcdir)/src/mman/munlockall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munmap.o: $(srcdir)/src/mman/munmap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/posix_madvise.o: $(srcdir)/src/mman/posix_madvise.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/shm_open.o: $(srcdir)/src/mman/shm_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_close.o: $(srcdir)/src/mq/mq_close.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_getattr.o: $(srcdir)/src/mq/mq_getattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_notify.o: $(srcdir)/src/mq/mq_notify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_open.o: $(srcdir)/src/mq/mq_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/x32/mq_open.o: $(srcdir)/src/mq/x32/mq_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_receive.o: $(srcdir)/src/mq/mq_receive.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_send.o: $(srcdir)/src/mq/mq_send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_setattr.o: $(srcdir)/src/mq/mq_setattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/x32/mq_setattr.o: $(srcdir)/src/mq/x32/mq_setattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_timedreceive.o: $(srcdir)/src/mq/mq_timedreceive.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_timedsend.o: $(srcdir)/src/mq/mq_timedsend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_unlink.o: $(srcdir)/src/mq/mq_unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/btowc.o: $(srcdir)/src/multibyte/btowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/c16rtomb.o: $(srcdir)/src/multibyte/c16rtomb.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/c32rtomb.o: $(srcdir)/src/multibyte/c32rtomb.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/internal.o: $(srcdir)/src/multibyte/internal.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mblen.o: $(srcdir)/src/multibyte/mblen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrlen.o: $(srcdir)/src/multibyte/mbrlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtoc16.o: $(srcdir)/src/multibyte/mbrtoc16.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtoc32.o: $(srcdir)/src/multibyte/mbrtoc32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtowc.o: $(srcdir)/src/multibyte/mbrtowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsinit.o: $(srcdir)/src/multibyte/mbsinit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsnrtowcs.o: $(srcdir)/src/multibyte/mbsnrtowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsrtowcs.o: $(srcdir)/src/multibyte/mbsrtowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbstowcs.o: $(srcdir)/src/multibyte/mbstowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbtowc.o: $(srcdir)/src/multibyte/mbtowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcrtomb.o: $(srcdir)/src/multibyte/wcrtomb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcsnrtombs.o: $(srcdir)/src/multibyte/wcsnrtombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcsrtombs.o: $(srcdir)/src/multibyte/wcsrtombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcstombs.o: $(srcdir)/src/multibyte/wcstombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wctob.o: $(srcdir)/src/multibyte/wctob.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wctomb.o: $(srcdir)/src/multibyte/wctomb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/accept.o: $(srcdir)/src/network/accept.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/accept4.o: $(srcdir)/src/network/accept4.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/bind.o: $(srcdir)/src/network/bind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/connect.o: $(srcdir)/src/network/connect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_comp.o: $(srcdir)/src/network/dn_comp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_expand.o: $(srcdir)/src/network/dn_expand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_skipname.o: $(srcdir)/src/network/dn_skipname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dns_parse.o: $(srcdir)/src/network/dns_parse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ent.o: $(srcdir)/src/network/ent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ether.o: $(srcdir)/src/network/ether.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/freeaddrinfo.o: $(srcdir)/src/network/freeaddrinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gai_strerror.o: $(srcdir)/src/network/gai_strerror.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getaddrinfo.o: $(srcdir)/src/network/getaddrinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyaddr.o: $(srcdir)/src/network/gethostbyaddr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyaddr_r.o: $(srcdir)/src/network/gethostbyaddr_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname.o: $(srcdir)/src/network/gethostbyname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname2.o: $(srcdir)/src/network/gethostbyname2.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname2_r.o: $(srcdir)/src/network/gethostbyname2_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname_r.o: $(srcdir)/src/network/gethostbyname_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getifaddrs.o: $(srcdir)/src/network/getifaddrs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getnameinfo.o: $(srcdir)/src/network/getnameinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getpeername.o: $(srcdir)/src/network/getpeername.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyname.o: $(srcdir)/src/network/getservbyname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyname_r.o: $(srcdir)/src/network/getservbyname_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyport.o: $(srcdir)/src/network/getservbyport.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyport_r.o: $(srcdir)/src/network/getservbyport_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getsockname.o: $(srcdir)/src/network/getsockname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getsockopt.o: $(srcdir)/src/network/getsockopt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/h_errno.o: $(srcdir)/src/network/h_errno.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/herror.o: $(srcdir)/src/network/herror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/hstrerror.o: $(srcdir)/src/network/hstrerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/htonl.o: $(srcdir)/src/network/htonl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/htons.o: $(srcdir)/src/network/htons.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_freenameindex.o: $(srcdir)/src/network/if_freenameindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_indextoname.o: $(srcdir)/src/network/if_indextoname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_nameindex.o: $(srcdir)/src/network/if_nameindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_nametoindex.o: $(srcdir)/src/network/if_nametoindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/in6addr_any.o: $(srcdir)/src/network/in6addr_any.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/in6addr_loopback.o: $(srcdir)/src/network/in6addr_loopback.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_addr.o: $(srcdir)/src/network/inet_addr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_aton.o: $(srcdir)/src/network/inet_aton.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_legacy.o: $(srcdir)/src/network/inet_legacy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_ntoa.o: $(srcdir)/src/network/inet_ntoa.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_ntop.o: $(srcdir)/src/network/inet_ntop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_pton.o: $(srcdir)/src/network/inet_pton.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/listen.o: $(srcdir)/src/network/listen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_ipliteral.o: $(srcdir)/src/network/lookup_ipliteral.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_name.o: $(srcdir)/src/network/lookup_name.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_serv.o: $(srcdir)/src/network/lookup_serv.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/netlink.o: $(srcdir)/src/network/netlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/netname.o: $(srcdir)/src/network/netname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ns_parse.o: $(srcdir)/src/network/ns_parse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ntohl.o: $(srcdir)/src/network/ntohl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ntohs.o: $(srcdir)/src/network/ntohs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/proto.o: $(srcdir)/src/network/proto.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recv.o: $(srcdir)/src/network/recv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvmmsg.o: $(srcdir)/src/network/recvmmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_init.o: $(srcdir)/src/network/res_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_mkquery.o: $(srcdir)/src/network/res_mkquery.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_msend.o: $(srcdir)/src/network/res_msend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_query.o: $(srcdir)/src/network/res_query.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_querydomain.o: $(srcdir)/src/network/res_querydomain.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_send.o: $(srcdir)/src/network/res_send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_state.o: $(srcdir)/src/network/res_state.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/resolvconf.o: $(srcdir)/src/network/resolvconf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvfrom.o: $(srcdir)/src/network/recvfrom.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvmsg.o: $(srcdir)/src/network/recvmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/send.o: $(srcdir)/src/network/send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendmmsg.o: $(srcdir)/src/network/sendmmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendmsg.o: $(srcdir)/src/network/sendmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendto.o: $(srcdir)/src/network/sendto.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/serv.o: $(srcdir)/src/network/serv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/setsockopt.o: $(srcdir)/src/network/setsockopt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/shutdown.o: $(srcdir)/src/network/shutdown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sockatmark.o: $(srcdir)/src/network/sockatmark.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/socket.o: $(srcdir)/src/network/socket.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/socketpair.o: $(srcdir)/src/network/socketpair.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetgrent.o: $(srcdir)/src/passwd/fgetgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetpwent.o: $(srcdir)/src/passwd/fgetpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetspent.o: $(srcdir)/src/passwd/fgetspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgr_a.o: $(srcdir)/src/passwd/getgr_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgr_r.o: $(srcdir)/src/passwd/getgr_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrent.o: $(srcdir)/src/passwd/getgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrent_a.o: $(srcdir)/src/passwd/getgrent_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrouplist.o: $(srcdir)/src/passwd/getgrouplist.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpw_a.o: $(srcdir)/src/passwd/getpw_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpw_r.o: $(srcdir)/src/passwd/getpw_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpwent.o: $(srcdir)/src/passwd/getpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpwent_a.o: $(srcdir)/src/passwd/getpwent_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspent.o: $(srcdir)/src/passwd/getspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspnam.o: $(srcdir)/src/passwd/getspnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspnam_r.o: $(srcdir)/src/passwd/getspnam_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/lckpwdf.o: $(srcdir)/src/passwd/lckpwdf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/nscd_query.o: $(srcdir)/src/passwd/nscd_query.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putgrent.o: $(srcdir)/src/passwd/putgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putpwent.o: $(srcdir)/src/passwd/putpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putspent.o: $(srcdir)/src/passwd/putspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/__rand48_step.o: $(srcdir)/src/prng/__rand48_step.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/__seed48.o: $(srcdir)/src/prng/__seed48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/drand48.o: $(srcdir)/src/prng/drand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/lcong48.o: $(srcdir)/src/prng/lcong48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/lrand48.o: $(srcdir)/src/prng/lrand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/mrand48.o: $(srcdir)/src/prng/mrand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/rand.o: $(srcdir)/src/prng/rand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/rand_r.o: $(srcdir)/src/prng/rand_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/random.o: $(srcdir)/src/prng/random.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/seed48.o: $(srcdir)/src/prng/seed48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/srand48.o: $(srcdir)/src/prng/srand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/_Fork.o: $(srcdir)/src/process/_Fork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execl.o: $(srcdir)/src/process/execl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execle.o: $(srcdir)/src/process/execle.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execlp.o: $(srcdir)/src/process/execlp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execv.o: $(srcdir)/src/process/execv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execve.o: $(srcdir)/src/process/execve.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execvp.o: $(srcdir)/src/process/execvp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/fexecve.o: $(srcdir)/src/process/fexecve.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/fork.o: $(srcdir)/src/process/fork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn.o: $(srcdir)/src/process/posix_spawn.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addchdir.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_addchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addclose.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_addclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_adddup2.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_adddup2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addfchdir.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_addfchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addopen.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_addopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_destroy.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_init.o: \
  $(srcdir)/src/process/posix_spawn_file_actions_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_destroy.o: \
  $(srcdir)/src/process/posix_spawnattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getflags.o: \
  $(srcdir)/src/process/posix_spawnattr_getflags.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getpgroup.o: \
  $(srcdir)/src/process/posix_spawnattr_getpgroup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getsigdefault.o: \
  $(srcdir)/src/process/posix_spawnattr_getsigdefault.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getsigmask.o: \
  $(srcdir)/src/process/posix_spawnattr_getsigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_init.o: \
  $(srcdir)/src/process/posix_spawnattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_sched.o: \
  $(srcdir)/src/process/posix_spawnattr_sched.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setflags.o: \
  $(srcdir)/src/process/posix_spawnattr_setflags.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setpgroup.o: \
  $(srcdir)/src/process/posix_spawnattr_setpgroup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setsigdefault.o: \
  $(srcdir)/src/process/posix_spawnattr_setsigdefault.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setsigmask.o: \
  $(srcdir)/src/process/posix_spawnattr_setsigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnp.o: $(srcdir)/src/process/posix_spawnp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/system.o: $(srcdir)/src/process/system.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/vfork.o: $(srcdir)/src/process/vfork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/wait.o: $(srcdir)/src/process/wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/waitid.o: $(srcdir)/src/process/waitid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/waitpid.o: $(srcdir)/src/process/waitpid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/fnmatch.o: $(srcdir)/src/regex/fnmatch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/glob.o: $(srcdir)/src/regex/glob.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regcomp.o: $(srcdir)/src/regex/regcomp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regerror.o: $(srcdir)/src/regex/regerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regexec.o: $(srcdir)/src/regex/regexec.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/tre-mem.o: $(srcdir)/src/regex/tre-mem.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/affinity.o: $(srcdir)/src/sched/affinity.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_cpucount.o: $(srcdir)/src/sched/sched_cpucount.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getcpu.o: $(srcdir)/src/sched/sched_getcpu.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getparam.o: $(srcdir)/src/sched/sched_getparam.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getscheduler.o: $(srcdir)/src/sched/sched_getscheduler.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_rr_get_interval.o: \
  $(srcdir)/src/sched/sched_rr_get_interval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_setparam.o: $(srcdir)/src/sched/sched_setparam.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_setscheduler.o: $(srcdir)/src/sched/sched_setscheduler.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_yield.o: $(srcdir)/src/sched/sched_yield.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_get_priority_max.o: \
  $(srcdir)/src/sched/sched_get_priority_max.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/hsearch.o: $(srcdir)/src/search/hsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/insque.o: $(srcdir)/src/search/insque.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/lsearch.o: $(srcdir)/src/search/lsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tdelete.o: $(srcdir)/src/search/tdelete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tdestroy.o: $(srcdir)/src/search/tdestroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tfind.o: $(srcdir)/src/search/tfind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tsearch.o: $(srcdir)/src/search/tsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/twalk.o: $(srcdir)/src/search/twalk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/poll.o: $(srcdir)/src/select/poll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/ppoll.o: $(srcdir)/src/select/ppoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/pselect.o: $(srcdir)/src/select/pselect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/select.o: $(srcdir)/src/select/select.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/longjmp.o: $(srcdir)/src/setjmp/longjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/setjmp.o: $(srcdir)/src/setjmp/setjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/block.o: $(srcdir)/src/signal/block.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/getitimer.o: $(srcdir)/src/signal/getitimer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/x32/getitimer.o: $(srcdir)/src/signal/x32/getitimer.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/kill.o: $(srcdir)/src/signal/kill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/killpg.o: $(srcdir)/src/signal/killpg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/psiginfo.o: $(srcdir)/src/signal/psiginfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/psignal.o: $(srcdir)/src/signal/psignal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/raise.o: $(srcdir)/src/signal/raise.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/restore.o: $(srcdir)/src/signal/restore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/setitimer.o: $(srcdir)/src/signal/setitimer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/x32/setitimer.o: $(srcdir)/src/signal/x32/setitimer.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaction.o: $(srcdir)/src/signal/sigaction.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaddset.o: $(srcdir)/src/signal/sigaddset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaltstack.o: $(srcdir)/src/signal/sigaltstack.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigandset.o: $(srcdir)/src/signal/sigandset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigdelset.o: $(srcdir)/src/signal/sigdelset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigemptyset.o: $(srcdir)/src/signal/sigemptyset.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigfillset.o: $(srcdir)/src/signal/sigfillset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sighold.o: $(srcdir)/src/signal/sighold.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigignore.o: $(srcdir)/src/signal/sigignore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/siginterrupt.o: $(srcdir)/src/signal/siginterrupt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigisemptyset.o: $(srcdir)/src/signal/sigisemptyset.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigismember.o: $(srcdir)/src/signal/sigismember.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/siglongjmp.o: $(srcdir)/src/signal/siglongjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/signal.o: $(srcdir)/src/signal/signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigorset.o: $(srcdir)/src/signal/sigorset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigpause.o: $(srcdir)/src/signal/sigpause.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigpending.o: $(srcdir)/src/signal/sigpending.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigprocmask.o: $(srcdir)/src/signal/sigprocmask.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigqueue.o: $(srcdir)/src/signal/sigqueue.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrelse.o: $(srcdir)/src/signal/sigrelse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrtmax.o: $(srcdir)/src/signal/sigrtmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrtmin.o: $(srcdir)/src/signal/sigrtmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigset.o: $(srcdir)/src/signal/sigset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsetjmp.o: $(srcdir)/src/signal/sigsetjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsetjmp_tail.o: $(srcdir)/src/signal/sigsetjmp_tail.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsuspend.o: $(srcdir)/src/signal/sigsuspend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigtimedwait.o: $(srcdir)/src/signal/sigtimedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigwait.o: $(srcdir)/src/signal/sigwait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigwaitinfo.o: $(srcdir)/src/signal/sigwaitinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/__xstat.o: $(srcdir)/src/stat/__xstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/chmod.o: $(srcdir)/src/stat/chmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fchmod.o: $(srcdir)/src/stat/fchmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fchmodat.o: $(srcdir)/src/stat/fchmodat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fstat.o: $(srcdir)/src/stat/fstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fstatat.o: $(srcdir)/src/stat/fstatat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/futimens.o: $(srcdir)/src/stat/futimens.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/futimesat.o: $(srcdir)/src/stat/futimesat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/lchmod.o: $(srcdir)/src/stat/lchmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/lstat.o: $(srcdir)/src/stat/lstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkdir.o: $(srcdir)/src/stat/mkdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkdirat.o: $(srcdir)/src/stat/mkdirat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkfifo.o: $(srcdir)/src/stat/mkfifo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkfifoat.o: $(srcdir)/src/stat/mkfifoat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mknod.o: $(srcdir)/src/stat/mknod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mknodat.o: $(srcdir)/src/stat/mknodat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/stat.o: $(srcdir)/src/stat/stat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/statvfs.o: $(srcdir)/src/stat/statvfs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/umask.o: $(srcdir)/src/stat/umask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/utimensat.o: $(srcdir)/src/stat/utimensat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fclose_ca.o: $(srcdir)/src/stdio/__fclose_ca.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fdopen.o: $(srcdir)/src/stdio/__fdopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fmodeflags.o: $(srcdir)/src/stdio/__fmodeflags.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fopen_rb_ca.o: $(srcdir)/src/stdio/__fopen_rb_ca.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__lockfile.o: $(srcdir)/src/stdio/__lockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__overflow.o: $(srcdir)/src/stdio/__overflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_close.o: $(srcdir)/src/stdio/__stdio_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_exit.o: $(srcdir)/src/stdio/__stdio_exit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_read.o: $(srcdir)/src/stdio/__stdio_read.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_seek.o: $(srcdir)/src/stdio/__stdio_seek.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_write.o: $(srcdir)/src/stdio/__stdio_write.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdout_write.o: $(srcdir)/src/stdio/__stdout_write.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__toread.o: $(srcdir)/src/stdio/__toread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__towrite.o: $(srcdir)/src/stdio/__towrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__uflow.o: $(srcdir)/src/stdio/__uflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/asprintf.o: $(srcdir)/src/stdio/asprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/clearerr.o: $(srcdir)/src/stdio/clearerr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/dprintf.o: $(srcdir)/src/stdio/dprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ext.o: $(srcdir)/src/stdio/ext.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ext2.o: $(srcdir)/src/stdio/ext2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fclose.o: $(srcdir)/src/stdio/fclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/feof.o: $(srcdir)/src/stdio/feof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ferror.o: $(srcdir)/src/stdio/ferror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fflush.o: $(srcdir)/src/stdio/fflush.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetc.o: $(srcdir)/src/stdio/fgetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetln.o: $(srcdir)/src/stdio/fgetln.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetpos.o: $(srcdir)/src/stdio/fgetpos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgets.o: $(srcdir)/src/stdio/fgets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetwc.o: $(srcdir)/src/stdio/fgetwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetws.o: $(srcdir)/src/stdio/fgetws.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fileno.o: $(srcdir)/src/stdio/fileno.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/flockfile.o: $(srcdir)/src/stdio/flockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fmemopen.o: $(srcdir)/src/stdio/fmemopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fopen.o: $(srcdir)/src/stdio/fopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fopencookie.o: $(srcdir)/src/stdio/fopencookie.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fprintf.o: $(srcdir)/src/stdio/fprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputc.o: $(srcdir)/src/stdio/fputc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputs.o: $(srcdir)/src/stdio/fputs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputwc.o: $(srcdir)/src/stdio/fputwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputws.o: $(srcdir)/src/stdio/fputws.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fread.o: $(srcdir)/src/stdio/fread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/freopen.o: $(srcdir)/src/stdio/freopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fscanf.o: $(srcdir)/src/stdio/fscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fseek.o: $(srcdir)/src/stdio/fseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fsetpos.o: $(srcdir)/src/stdio/fsetpos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ftell.o: $(srcdir)/src/stdio/ftell.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ftrylockfile.o: $(srcdir)/src/stdio/ftrylockfile.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/funlockfile.o: $(srcdir)/src/stdio/funlockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwide.o: $(srcdir)/src/stdio/fwide.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwprintf.o: $(srcdir)/src/stdio/fwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwrite.o: $(srcdir)/src/stdio/fwrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwscanf.o: $(srcdir)/src/stdio/fwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getc.o: $(srcdir)/src/stdio/getc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getc_unlocked.o: $(srcdir)/src/stdio/getc_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getchar.o: $(srcdir)/src/stdio/getchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getchar_unlocked.o: $(srcdir)/src/stdio/getchar_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getdelim.o: $(srcdir)/src/stdio/getdelim.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getline.o: $(srcdir)/src/stdio/getline.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/gets.o: $(srcdir)/src/stdio/gets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getw.o: $(srcdir)/src/stdio/getw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getwc.o: $(srcdir)/src/stdio/getwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getwchar.o: $(srcdir)/src/stdio/getwchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ofl.o: $(srcdir)/src/stdio/ofl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ofl_add.o: $(srcdir)/src/stdio/ofl_add.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/open_memstream.o: $(srcdir)/src/stdio/open_memstream.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/open_wmemstream.o: $(srcdir)/src/stdio/open_wmemstream.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/pclose.o: $(srcdir)/src/stdio/pclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/perror.o: $(srcdir)/src/stdio/perror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/popen.o: $(srcdir)/src/stdio/popen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/printf.o: $(srcdir)/src/stdio/printf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putc.o: $(srcdir)/src/stdio/putc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putc_unlocked.o: $(srcdir)/src/stdio/putc_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putchar.o: $(srcdir)/src/stdio/putchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putchar_unlocked.o: $(srcdir)/src/stdio/putchar_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/puts.o: $(srcdir)/src/stdio/puts.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putw.o: $(srcdir)/src/stdio/putw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putwc.o: $(srcdir)/src/stdio/putwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putwchar.o: $(srcdir)/src/stdio/putwchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/remove.o: $(srcdir)/src/stdio/remove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/rename.o: $(srcdir)/src/stdio/rename.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/rewind.o: $(srcdir)/src/stdio/rewind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/scanf.o: $(srcdir)/src/stdio/scanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setbuf.o: $(srcdir)/src/stdio/setbuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setbuffer.o: $(srcdir)/src/stdio/setbuffer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setlinebuf.o: $(srcdir)/src/stdio/setlinebuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setvbuf.o: $(srcdir)/src/stdio/setvbuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/snprintf.o: $(srcdir)/src/stdio/snprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/sprintf.o: $(srcdir)/src/stdio/sprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/sscanf.o: $(srcdir)/src/stdio/sscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stderr.o: $(srcdir)/src/stdio/stderr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stdin.o: $(srcdir)/src/stdio/stdin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stdout.o: $(srcdir)/src/stdio/stdout.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/swprintf.o: $(srcdir)/src/stdio/swprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/swscanf.o: $(srcdir)/src/stdio/swscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tempnam.o: $(srcdir)/src/stdio/tempnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tmpfile.o: $(srcdir)/src/stdio/tmpfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tmpnam.o: $(srcdir)/src/stdio/tmpnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ungetc.o: $(srcdir)/src/stdio/ungetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ungetwc.o: $(srcdir)/src/stdio/ungetwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vasprintf.o: $(srcdir)/src/stdio/vasprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vdprintf.o: $(srcdir)/src/stdio/vdprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfprintf.o: $(srcdir)/src/stdio/vfprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfscanf.o: $(srcdir)/src/stdio/vfscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfwprintf.o: $(srcdir)/src/stdio/vfwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfwscanf.o: $(srcdir)/src/stdio/vfwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vprintf.o: $(srcdir)/src/stdio/vprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vscanf.o: $(srcdir)/src/stdio/vscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsnprintf.o: $(srcdir)/src/stdio/vsnprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsprintf.o: $(srcdir)/src/stdio/vsprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsscanf.o: $(srcdir)/src/stdio/vsscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vswprintf.o: $(srcdir)/src/stdio/vswprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vswscanf.o: $(srcdir)/src/stdio/vswscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vwprintf.o: $(srcdir)/src/stdio/vwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vwscanf.o: $(srcdir)/src/stdio/vwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/wprintf.o: $(srcdir)/src/stdio/wprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/wscanf.o: $(srcdir)/src/stdio/wscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/abs.o: $(srcdir)/src/stdlib/abs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atof.o: $(srcdir)/src/stdlib/atof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atoi.o: $(srcdir)/src/stdlib/atoi.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atol.o: $(srcdir)/src/stdlib/atol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atoll.o: $(srcdir)/src/stdlib/atoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/bsearch.o: $(srcdir)/src/stdlib/bsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/div.o: $(srcdir)/src/stdlib/div.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/ecvt.o: $(srcdir)/src/stdlib/ecvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/fcvt.o: $(srcdir)/src/stdlib/fcvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/gcvt.o: $(srcdir)/src/stdlib/gcvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/imaxabs.o: $(srcdir)/src/stdlib/imaxabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/imaxdiv.o: $(srcdir)/src/stdlib/imaxdiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/labs.o: $(srcdir)/src/stdlib/labs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/ldiv.o: $(srcdir)/src/stdlib/ldiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/llabs.o: $(srcdir)/src/stdlib/llabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/lldiv.o: $(srcdir)/src/stdlib/lldiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/qsort.o: $(srcdir)/src/stdlib/qsort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/qsort_nr.o: $(srcdir)/src/stdlib/qsort_nr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/strtod.o: $(srcdir)/src/stdlib/strtod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/strtol.o: $(srcdir)/src/stdlib/strtol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/wcstod.o: $(srcdir)/src/stdlib/wcstod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/wcstol.o: $(srcdir)/src/stdlib/wcstol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bcmp.o: $(srcdir)/src/string/bcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bcopy.o: $(srcdir)/src/string/bcopy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bzero.o: $(srcdir)/src/string/bzero.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/explicit_bzero.o: $(srcdir)/src/string/explicit_bzero.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/index.o: $(srcdir)/src/string/index.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memccpy.o: $(srcdir)/src/string/memccpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memchr.o: $(srcdir)/src/string/memchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memcmp.o: $(srcdir)/src/string/memcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memcpy.o: $(srcdir)/src/string/memcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memmem.o: $(srcdir)/src/string/memmem.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memmove.o: $(srcdir)/src/string/memmove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/mempcpy.o: $(srcdir)/src/string/mempcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memrchr.o: $(srcdir)/src/string/memrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memset.o: $(srcdir)/src/string/memset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/rindex.o: $(srcdir)/src/string/rindex.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/stpcpy.o: $(srcdir)/src/string/stpcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/stpncpy.o: $(srcdir)/src/string/stpncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcasecmp.o: $(srcdir)/src/string/strcasecmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcasestr.o: $(srcdir)/src/string/strcasestr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcat.o: $(srcdir)/src/string/strcat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strchr.o: $(srcdir)/src/string/strchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strchrnul.o: $(srcdir)/src/string/strchrnul.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcmp.o: $(srcdir)/src/string/strcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcpy.o: $(srcdir)/src/string/strcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcspn.o: $(srcdir)/src/string/strcspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strdup.o: $(srcdir)/src/string/strdup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strerror_r.o: $(srcdir)/src/string/strerror_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlcat.o: $(srcdir)/src/string/strlcat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlcpy.o: $(srcdir)/src/string/strlcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlen.o: $(srcdir)/src/string/strlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncasecmp.o: $(srcdir)/src/string/strncasecmp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncat.o: $(srcdir)/src/string/strncat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncmp.o: $(srcdir)/src/string/strncmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncpy.o: $(srcdir)/src/string/strncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strndup.o: $(srcdir)/src/string/strndup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strnlen.o: $(srcdir)/src/string/strnlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strpbrk.o: $(srcdir)/src/string/strpbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strrchr.o: $(srcdir)/src/string/strrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strsep.o: $(srcdir)/src/string/strsep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strsignal.o: $(srcdir)/src/string/strsignal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strspn.o: $(srcdir)/src/string/strspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strstr.o: $(srcdir)/src/string/strstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strtok.o: $(srcdir)/src/string/strtok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strtok_r.o: $(srcdir)/src/string/strtok_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strverscmp.o: $(srcdir)/src/string/strverscmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/swab.o: $(srcdir)/src/string/swab.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcpcpy.o: $(srcdir)/src/string/wcpcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcpncpy.o: $(srcdir)/src/string/wcpncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscasecmp.o: $(srcdir)/src/string/wcscasecmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscasecmp_l.o: $(srcdir)/src/string/wcscasecmp_l.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscat.o: $(srcdir)/src/string/wcscat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcschr.o: $(srcdir)/src/string/wcschr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscmp.o: $(srcdir)/src/string/wcscmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscpy.o: $(srcdir)/src/string/wcscpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscspn.o: $(srcdir)/src/string/wcscspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsdup.o: $(srcdir)/src/string/wcsdup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcslen.o: $(srcdir)/src/string/wcslen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncasecmp.o: $(srcdir)/src/string/wcsncasecmp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncasecmp_l.o: $(srcdir)/src/string/wcsncasecmp_l.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncat.o: $(srcdir)/src/string/wcsncat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncmp.o: $(srcdir)/src/string/wcsncmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncpy.o: $(srcdir)/src/string/wcsncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsnlen.o: $(srcdir)/src/string/wcsnlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcspbrk.o: $(srcdir)/src/string/wcspbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsrchr.o: $(srcdir)/src/string/wcsrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsspn.o: $(srcdir)/src/string/wcsspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsstr.o: $(srcdir)/src/string/wcsstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcstok.o: $(srcdir)/src/string/wcstok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcswcs.o: $(srcdir)/src/string/wcswcs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemchr.o: $(srcdir)/src/string/wmemchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemcmp.o: $(srcdir)/src/string/wmemcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemcpy.o: $(srcdir)/src/string/wmemcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemmove.o: $(srcdir)/src/string/wmemmove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemset.o: $(srcdir)/src/string/wmemset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/__randname.o: $(srcdir)/src/temp/__randname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkdtemp.o: $(srcdir)/src/temp/mkdtemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkostemp.o: $(srcdir)/src/temp/mkostemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkostemps.o: $(srcdir)/src/temp/mkostemps.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkstemp.o: $(srcdir)/src/temp/mkstemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkstemps.o: $(srcdir)/src/temp/mkstemps.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mktemp.o: $(srcdir)/src/temp/mktemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfgetospeed.o: $(srcdir)/src/termios/cfgetospeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfmakeraw.o: $(srcdir)/src/termios/cfmakeraw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfsetospeed.o: $(srcdir)/src/termios/cfsetospeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfsetspeed.o: $(srcdir)/src/termios/cfsetspeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcdrain.o: $(srcdir)/src/termios/tcdrain.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcflow.o: $(srcdir)/src/termios/tcflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcflush.o: $(srcdir)/src/termios/tcflush.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetattr.o: $(srcdir)/src/termios/tcgetattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetsid.o: $(srcdir)/src/termios/tcgetsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsendbreak.o: $(srcdir)/src/termios/tcsendbreak.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsetattr.o: $(srcdir)/src/termios/tcsetattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetwinsize.o: $(srcdir)/src/termios/tcgetwinsize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsetwinsize.o: $(srcdir)/src/termios/tcsetwinsize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__lock.o: $(srcdir)/src/thread/__lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__set_thread_area.o: $(srcdir)/src/thread/__set_thread_area.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/aarch64/__set_thread_area.o: \
  $(srcdir)/src/thread/aarch64/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/arm/__set_thread_area.o: \
  $(srcdir)/src/thread/arm/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sh/__set_thread_area.o: \
  $(srcdir)/src/thread/sh/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__syscall_cp.o: $(srcdir)/src/thread/__syscall_cp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__timedwait.o: $(srcdir)/src/thread/__timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__tls_get_addr.o: $(srcdir)/src/thread/__tls_get_addr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__unmapself.o: $(srcdir)/src/thread/__unmapself.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sh/__unmapself.o: $(srcdir)/src/thread/sh/__unmapself.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__wait.o: $(srcdir)/src/thread/__wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/call_once.o: $(srcdir)/src/thread/call_once.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/clone.o: $(srcdir)/src/thread/clone.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_broadcast.o: $(srcdir)/src/thread/cnd_broadcast.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_destroy.o: $(srcdir)/src/thread/cnd_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_init.o: $(srcdir)/src/thread/cnd_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_signal.o: $(srcdir)/src/thread/cnd_signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_timedwait.o: $(srcdir)/src/thread/cnd_timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_wait.o: $(srcdir)/src/thread/cnd_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/default_attr.o: $(srcdir)/src/thread/default_attr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/lock_ptc.o: $(srcdir)/src/thread/lock_ptc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_destroy.o: $(srcdir)/src/thread/mtx_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_init.o: $(srcdir)/src/thread/mtx_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_lock.o: $(srcdir)/src/thread/mtx_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_timedlock.o: $(srcdir)/src/thread/mtx_timedlock.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_trylock.o: $(srcdir)/src/thread/mtx_trylock.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_unlock.o: $(srcdir)/src/thread/mtx_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_atfork.o: $(srcdir)/src/thread/pthread_atfork.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_destroy.o: \
  $(srcdir)/src/thread/pthread_attr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_get.o: $(srcdir)/src/thread/pthread_attr_get.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_init.o: $(srcdir)/src/thread/pthread_attr_init.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setdetachstate.o: \
  $(srcdir)/src/thread/pthread_attr_setdetachstate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setguardsize.o: \
  $(srcdir)/src/thread/pthread_attr_setguardsize.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setinheritsched.o: \
  $(srcdir)/src/thread/pthread_attr_setinheritsched.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setschedparam.o: \
  $(srcdir)/src/thread/pthread_attr_setschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setschedpolicy.o: \
  $(srcdir)/src/thread/pthread_attr_setschedpolicy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setscope.o: \
  $(srcdir)/src/thread/pthread_attr_setscope.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setstack.o: \
  $(srcdir)/src/thread/pthread_attr_setstack.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setstacksize.o: \
  $(srcdir)/src/thread/pthread_attr_setstacksize.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_destroy.o: \
  $(srcdir)/src/thread/pthread_barrier_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_init.o: \
  $(srcdir)/src/thread/pthread_barrier_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_wait.o: \
  $(srcdir)/src/thread/pthread_barrier_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_destroy.o: \
  $(srcdir)/src/thread/pthread_barrierattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_init.o: \
  $(srcdir)/src/thread/pthread_barrierattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_setpshared.o: \
  $(srcdir)/src/thread/pthread_barrierattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cancel.o: $(srcdir)/src/thread/pthread_cancel.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cleanup_push.o: \
  $(srcdir)/src/thread/pthread_cleanup_push.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_broadcast.o: \
  $(srcdir)/src/thread/pthread_cond_broadcast.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_destroy.o: \
  $(srcdir)/src/thread/pthread_cond_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_init.o: $(srcdir)/src/thread/pthread_cond_init.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_signal.o: \
  $(srcdir)/src/thread/pthread_cond_signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_timedwait.o: \
  $(srcdir)/src/thread/pthread_cond_timedwait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_wait.o: $(srcdir)/src/thread/pthread_cond_wait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_destroy.o: \
  $(srcdir)/src/thread/pthread_condattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_init.o: \
  $(srcdir)/src/thread/pthread_condattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_setclock.o: \
  $(srcdir)/src/thread/pthread_condattr_setclock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_setpshared.o: \
  $(srcdir)/src/thread/pthread_condattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_create.o: $(srcdir)/src/thread/pthread_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_detach.o: $(srcdir)/src/thread/pthread_detach.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_equal.o: $(srcdir)/src/thread/pthread_equal.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getattr_np.o: \
  $(srcdir)/src/thread/pthread_getattr_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getconcurrency.o: \
  $(srcdir)/src/thread/pthread_getconcurrency.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getcpuclockid.o: \
  $(srcdir)/src/thread/pthread_getcpuclockid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getname_np.o: \
  $(srcdir)/src/thread/pthread_getname_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getschedparam.o: \
  $(srcdir)/src/thread/pthread_getschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getspecific.o: \
  $(srcdir)/src/thread/pthread_getspecific.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_join.o: $(srcdir)/src/thread/pthread_join.c \
   $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_key_create.o: \
  $(srcdir)/src/thread/pthread_key_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_kill.o: $(srcdir)/src/thread/pthread_kill.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_consistent.o: \
  $(srcdir)/src/thread/pthread_mutex_consistent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_destroy.o: \
  $(srcdir)/src/thread/pthread_mutex_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_getprioceiling.o: \
  $(srcdir)/src/thread/pthread_mutex_getprioceiling.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_init.o: \
  $(srcdir)/src/thread/pthread_mutex_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_lock.o: \
  $(srcdir)/src/thread/pthread_mutex_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_setprioceiling.o: \
  $(srcdir)/src/thread/pthread_mutex_setprioceiling.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_timedlock.o: \
  $(srcdir)/src/thread/pthread_mutex_timedlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_trylock.o: \
  $(srcdir)/src/thread/pthread_mutex_trylock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_unlock.o: \
  $(srcdir)/src/thread/pthread_mutex_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_destroy.o: \
  $(srcdir)/src/thread/pthread_mutexattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_init.o: \
  $(srcdir)/src/thread/pthread_mutexattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setprotocol.o: \
  $(srcdir)/src/thread/pthread_mutexattr_setprotocol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setpshared.o: \
  $(srcdir)/src/thread/pthread_mutexattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setrobust.o: \
  $(srcdir)/src/thread/pthread_mutexattr_setrobust.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_settype.o: \
  $(srcdir)/src/thread/pthread_mutexattr_settype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_once.o: $(srcdir)/src/thread/pthread_once.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_destroy.o: \
  $(srcdir)/src/thread/pthread_rwlock_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_init.o: \
  $(srcdir)/src/thread/pthread_rwlock_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_rdlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_rdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_timedrdlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_timedrdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_timedwrlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_timedwrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_tryrdlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_tryrdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_trywrlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_trywrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_unlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_wrlock.o: \
  $(srcdir)/src/thread/pthread_rwlock_wrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_destroy.o: \
  $(srcdir)/src/thread/pthread_rwlockattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_init.o: \
  $(srcdir)/src/thread/pthread_rwlockattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_setpshared.o: \
  $(srcdir)/src/thread/pthread_rwlockattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_self.o: $(srcdir)/src/thread/pthread_self.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setattr_default_np.o: \
  $(srcdir)/src/thread/pthread_setattr_default_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setcancelstate.o: \
  $(srcdir)/src/thread/pthread_setcancelstate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setcanceltype.o: \
  $(srcdir)/src/thread/pthread_setcanceltype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setconcurrency.o: \
  $(srcdir)/src/thread/pthread_setconcurrency.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setname_np.o: \
  $(srcdir)/src/thread/pthread_setname_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setschedparam.o: \
  $(srcdir)/src/thread/pthread_setschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setschedprio.o: \
  $(srcdir)/src/thread/pthread_setschedprio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setspecific.o: \
  $(srcdir)/src/thread/pthread_setspecific.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_sigmask.o: \
  $(srcdir)/src/thread/pthread_sigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_destroy.o: \
  $(srcdir)/src/thread/pthread_spin_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_init.o: \
  $(srcdir)/src/thread/pthread_spin_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_lock.o: \
  $(srcdir)/src/thread/pthread_spin_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_trylock.o: \
  $(srcdir)/src/thread/pthread_spin_trylock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_unlock.o: \
  $(srcdir)/src/thread/pthread_spin_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_testcancel.o: \
  $(srcdir)/src/thread/pthread_testcancel.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_destroy.o: $(srcdir)/src/thread/sem_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_getvalue.o: $(srcdir)/src/thread/sem_getvalue.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_init.o: $(srcdir)/src/thread/sem_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_open.o: $(srcdir)/src/thread/sem_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_post.o: $(srcdir)/src/thread/sem_post.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_timedwait.o: $(srcdir)/src/thread/sem_timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_trywait.o: $(srcdir)/src/thread/sem_trywait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_unlink.o: $(srcdir)/src/thread/sem_unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_wait.o: $(srcdir)/src/thread/sem_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/synccall.o: $(srcdir)/src/thread/synccall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/syscall_cp.o: $(srcdir)/src/thread/syscall_cp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_create.o: $(srcdir)/src/thread/thrd_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_exit.o: $(srcdir)/src/thread/thrd_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_join.o: $(srcdir)/src/thread/thrd_join.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_sleep.o: $(srcdir)/src/thread/thrd_sleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_yield.o: $(srcdir)/src/thread/thrd_yield.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tls.o: $(srcdir)/src/thread/tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_create.o: $(srcdir)/src/thread/tss_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_delete.o: $(srcdir)/src/thread/tss_delete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_set.o: $(srcdir)/src/thread/tss_set.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/vmlock.o: $(srcdir)/src/thread/vmlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__map_file.o: $(srcdir)/src/time/__map_file.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__month_to_secs.o: $(srcdir)/src/time/__month_to_secs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__secs_to_tm.o: $(srcdir)/src/time/__secs_to_tm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__tm_to_secs.o: $(srcdir)/src/time/__tm_to_secs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__tz.o: $(srcdir)/src/time/__tz.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__utc.o: $(srcdir)/src/time/__utc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__year_to_secs.o: $(srcdir)/src/time/__year_to_secs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/asctime.o: $(srcdir)/src/time/asctime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/asctime_r.o: $(srcdir)/src/time/asctime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock.o: $(srcdir)/src/time/clock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_getcpuclockid.o: $(srcdir)/src/time/clock_getcpuclockid.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_getres.o: $(srcdir)/src/time/clock_getres.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_gettime.o: $(srcdir)/src/time/clock_gettime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_nanosleep.o: $(srcdir)/src/time/clock_nanosleep.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_settime.o: $(srcdir)/src/time/clock_settime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ctime.o: $(srcdir)/src/time/ctime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ctime_r.o: $(srcdir)/src/time/ctime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/difftime.o: $(srcdir)/src/time/difftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ftime.o: $(srcdir)/src/time/ftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/getdate.o: $(srcdir)/src/time/getdate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gettimeofday.o: $(srcdir)/src/time/gettimeofday.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gmtime.o: $(srcdir)/src/time/gmtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gmtime_r.o: $(srcdir)/src/time/gmtime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/localtime.o: $(srcdir)/src/time/localtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/localtime_r.o: $(srcdir)/src/time/localtime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/mktime.o: $(srcdir)/src/time/mktime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/nanosleep.o: $(srcdir)/src/time/nanosleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/strftime.o: $(srcdir)/src/time/strftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/strptime.o: $(srcdir)/src/time/strptime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/time.o: $(srcdir)/src/time/time.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timegm.o: $(srcdir)/src/time/timegm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_create.o: $(srcdir)/src/time/timer_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_delete.o: $(srcdir)/src/time/timer_delete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_getoverrun.o: $(srcdir)/src/time/timer_getoverrun.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_gettime.o: $(srcdir)/src/time/timer_gettime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_settime.o: $(srcdir)/src/time/timer_settime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/times.o: $(srcdir)/src/time/times.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timespec_get.o: $(srcdir)/src/time/timespec_get.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/utime.o: $(srcdir)/src/time/utime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/wcsftime.o: $(srcdir)/src/time/wcsftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/_exit.o: $(srcdir)/src/unistd/_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/access.o: $(srcdir)/src/unistd/access.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/acct.o: $(srcdir)/src/unistd/acct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/alarm.o: $(srcdir)/src/unistd/alarm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/chdir.o: $(srcdir)/src/unistd/chdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/chown.o: $(srcdir)/src/unistd/chown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/close.o: $(srcdir)/src/unistd/close.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ctermid.o: $(srcdir)/src/unistd/ctermid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup.o: $(srcdir)/src/unistd/dup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup2.o: $(srcdir)/src/unistd/dup2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup3.o: $(srcdir)/src/unistd/dup3.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/faccessat.o: $(srcdir)/src/unistd/faccessat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchdir.o: $(srcdir)/src/unistd/fchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchown.o: $(srcdir)/src/unistd/fchown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchownat.o: $(srcdir)/src/unistd/fchownat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fdatasync.o: $(srcdir)/src/unistd/fdatasync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fsync.o: $(srcdir)/src/unistd/fsync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ftruncate.o: $(srcdir)/src/unistd/ftruncate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getcwd.o: $(srcdir)/src/unistd/getcwd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getegid.o: $(srcdir)/src/unistd/getegid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/geteuid.o: $(srcdir)/src/unistd/geteuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getgid.o: $(srcdir)/src/unistd/getgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getgroups.o: $(srcdir)/src/unistd/getgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/gethostname.o: $(srcdir)/src/unistd/gethostname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getlogin.o: $(srcdir)/src/unistd/getlogin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getlogin_r.o: $(srcdir)/src/unistd/getlogin_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpgid.o: $(srcdir)/src/unistd/getpgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpgrp.o: $(srcdir)/src/unistd/getpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpid.o: $(srcdir)/src/unistd/getpid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getppid.o: $(srcdir)/src/unistd/getppid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getsid.o: $(srcdir)/src/unistd/getsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getuid.o: $(srcdir)/src/unistd/getuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/isatty.o: $(srcdir)/src/unistd/isatty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/lchown.o: $(srcdir)/src/unistd/lchown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/link.o: $(srcdir)/src/unistd/link.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/linkat.o: $(srcdir)/src/unistd/linkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/lseek.o: $(srcdir)/src/unistd/lseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/mipsn32/lseek.o: $(srcdir)/src/unistd/mipsn32/lseek.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/x32/lseek.o: $(srcdir)/src/unistd/x32/lseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/nice.o: $(srcdir)/src/unistd/nice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pause.o: $(srcdir)/src/unistd/pause.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pipe.o: $(srcdir)/src/unistd/pipe.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pipe2.o: $(srcdir)/src/unistd/pipe2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/posix_close.o: $(srcdir)/src/unistd/posix_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pread.o: $(srcdir)/src/unistd/pread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/preadv.o: $(srcdir)/src/unistd/preadv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pwrite.o: $(srcdir)/src/unistd/pwrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pwritev.o: $(srcdir)/src/unistd/pwritev.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/read.o: $(srcdir)/src/unistd/read.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readlink.o: $(srcdir)/src/unistd/readlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readlinkat.o: $(srcdir)/src/unistd/readlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readv.o: $(srcdir)/src/unistd/readv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/renameat.o: $(srcdir)/src/unistd/renameat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/rmdir.o: $(srcdir)/src/unistd/rmdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setegid.o: $(srcdir)/src/unistd/setegid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/seteuid.o: $(srcdir)/src/unistd/seteuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setgid.o: $(srcdir)/src/unistd/setgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setpgid.o: $(srcdir)/src/unistd/setpgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setpgrp.o: $(srcdir)/src/unistd/setpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setregid.o: $(srcdir)/src/unistd/setregid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setresgid.o: $(srcdir)/src/unistd/setresgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setresuid.o: $(srcdir)/src/unistd/setresuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setreuid.o: $(srcdir)/src/unistd/setreuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setsid.o: $(srcdir)/src/unistd/setsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setuid.o: $(srcdir)/src/unistd/setuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setxid.o: $(srcdir)/src/unistd/setxid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/sleep.o: $(srcdir)/src/unistd/sleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/symlink.o: $(srcdir)/src/unistd/symlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/symlinkat.o: $(srcdir)/src/unistd/symlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/sync.o: $(srcdir)/src/unistd/sync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/tcgetpgrp.o: $(srcdir)/src/unistd/tcgetpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/tcsetpgrp.o: $(srcdir)/src/unistd/tcsetpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/truncate.o: $(srcdir)/src/unistd/truncate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ttyname.o: $(srcdir)/src/unistd/ttyname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ttyname_r.o: $(srcdir)/src/unistd/ttyname_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ualarm.o: $(srcdir)/src/unistd/ualarm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/unlink.o: $(srcdir)/src/unistd/unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/unlinkat.o: $(srcdir)/src/unistd/unlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/usleep.o: $(srcdir)/src/unistd/usleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/write.o: $(srcdir)/src/unistd/write.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/writev.o: $(srcdir)/src/unistd/writev.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<

$(objbuilddir)/crt/aarch64/crti.lo: $(srcdir)/crt/aarch64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/aarch64/crtn.lo: $(srcdir)/crt/aarch64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/arm/crti.lo: $(srcdir)/crt/arm/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/arm/crtn.lo: $(srcdir)/crt/arm/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/i386/crti.lo: $(srcdir)/crt/i386/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/i386/crtn.lo: $(srcdir)/crt/i386/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/microblaze/crti.lo: $(srcdir)/crt/microblaze/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/microblaze/crtn.lo: $(srcdir)/crt/microblaze/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips/crti.lo: $(srcdir)/crt/mips/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips/crtn.lo: $(srcdir)/crt/mips/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips64/crti.lo: $(srcdir)/crt/mips64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mips64/crtn.lo: $(srcdir)/crt/mips64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mipsn32/crti.lo: $(srcdir)/crt/mipsn32/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/mipsn32/crtn.lo: $(srcdir)/crt/mipsn32/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/or1k/crti.lo: $(srcdir)/crt/or1k/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/or1k/crtn.lo: $(srcdir)/crt/or1k/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc/crti.lo: $(srcdir)/crt/powerpc/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc/crtn.lo: $(srcdir)/crt/powerpc/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc64/crti.lo: $(srcdir)/crt/powerpc64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/powerpc64/crtn.lo: $(srcdir)/crt/powerpc64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/s390x/crti.lo: $(srcdir)/crt/s390x/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/s390x/crtn.lo: $(srcdir)/crt/s390x/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/sh/crti.lo: $(srcdir)/crt/sh/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/sh/crtn.lo: $(srcdir)/crt/sh/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x32/crti.lo: $(srcdir)/crt/x32/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x32/crtn.lo: $(srcdir)/crt/x32/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x86_64/crti.lo: $(srcdir)/crt/x86_64/crti.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/crt/x86_64/crtn.lo: $(srcdir)/crt/x86_64/crtn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/aarch64/fenv.lo: $(srcdir)/src/fenv/aarch64/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/i386/fenv.lo: $(srcdir)/src/fenv/i386/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/x32/fenv.lo: $(srcdir)/src/fenv/x32/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/fenv/x86_64/fenv.lo: $(srcdir)/src/fenv/x86_64/fenv.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/internal/i386/defsysinfo.lo: $(srcdir)/src/internal/i386/defsysinfo.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/aarch64/dlsym.lo: $(srcdir)/src/ldso/aarch64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/aarch64/tlsdesc.lo: $(srcdir)/src/ldso/aarch64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/arm/dlsym.lo: $(srcdir)/src/ldso/arm/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/i386/dlsym.lo: $(srcdir)/src/ldso/i386/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/i386/tlsdesc.lo: $(srcdir)/src/ldso/i386/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/loongarch64/dlsym.lo: $(srcdir)/src/ldso/loongarch64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/loongarch64/tlsdesc.lo: $(srcdir)/src/ldso/loongarch64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/m68k/dlsym.lo: $(srcdir)/src/ldso/m68k/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/microblaze/dlsym.lo: $(srcdir)/src/ldso/microblaze/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mips/dlsym.lo: $(srcdir)/src/ldso/mips/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mips64/dlsym.lo: $(srcdir)/src/ldso/mips64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/mipsn32/dlsym.lo: $(srcdir)/src/ldso/mipsn32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/or1k/dlsym.lo: $(srcdir)/src/ldso/or1k/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/powerpc/dlsym.lo: $(srcdir)/src/ldso/powerpc/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/powerpc64/dlsym.lo: $(srcdir)/src/ldso/powerpc64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv32/dlsym.lo: $(srcdir)/src/ldso/riscv32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv64/dlsym.lo: $(srcdir)/src/ldso/riscv64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/riscv64/tlsdesc.lo: $(srcdir)/src/ldso/riscv64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/s390x/dlsym.lo: $(srcdir)/src/ldso/s390x/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/sh/dlsym.lo: $(srcdir)/src/ldso/sh/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x32/dlsym.lo: $(srcdir)/src/ldso/x32/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x86_64/dlsym.lo: $(srcdir)/src/ldso/x86_64/dlsym.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/ldso/x86_64/tlsdesc.lo: $(srcdir)/src/ldso/x86_64/tlsdesc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/__invtrigl.lo: $(srcdir)/src/math/i386/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acos.lo: $(srcdir)/src/math/i386/acos.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acosf.lo: $(srcdir)/src/math/i386/acosf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/acosl.lo: $(srcdir)/src/math/i386/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asin.lo: $(srcdir)/src/math/i386/asin.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asinf.lo: $(srcdir)/src/math/i386/asinf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/asinl.lo: $(srcdir)/src/math/i386/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan.lo: $(srcdir)/src/math/i386/atan.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2.lo: $(srcdir)/src/math/i386/atan2.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2f.lo: $(srcdir)/src/math/i386/atan2f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atan2l.lo: $(srcdir)/src/math/i386/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atanf.lo: $(srcdir)/src/math/i386/atanf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/atanl.lo: $(srcdir)/src/math/i386/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceil.lo: $(srcdir)/src/math/i386/ceil.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceilf.lo: $(srcdir)/src/math/i386/ceilf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ceill.lo: $(srcdir)/src/math/i386/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/exp_ld.lo: $(srcdir)/src/math/i386/exp_ld.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/exp2l.lo: $(srcdir)/src/math/i386/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/expl.lo: $(srcdir)/src/math/i386/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/expm1l.lo: $(srcdir)/src/math/i386/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floor.lo: $(srcdir)/src/math/i386/floor.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floorf.lo: $(srcdir)/src/math/i386/floorf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/floorl.lo: $(srcdir)/src/math/i386/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/hypot.lo: $(srcdir)/src/math/i386/hypot.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/hypotf.lo: $(srcdir)/src/math/i386/hypotf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexp.lo: $(srcdir)/src/math/i386/ldexp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexpf.lo: $(srcdir)/src/math/i386/ldexpf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/ldexpl.lo: $(srcdir)/src/math/i386/ldexpl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log.lo: $(srcdir)/src/math/i386/log.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10.lo: $(srcdir)/src/math/i386/log10.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10f.lo: $(srcdir)/src/math/i386/log10f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log10l.lo: $(srcdir)/src/math/i386/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1p.lo: $(srcdir)/src/math/i386/log1p.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1pf.lo: $(srcdir)/src/math/i386/log1pf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log1pl.lo: $(srcdir)/src/math/i386/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2.lo: $(srcdir)/src/math/i386/log2.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2f.lo: $(srcdir)/src/math/i386/log2f.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/log2l.lo: $(srcdir)/src/math/i386/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/logf.lo: $(srcdir)/src/math/i386/logf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/logl.lo: $(srcdir)/src/math/i386/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquo.lo: $(srcdir)/src/math/i386/remquo.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquof.lo: $(srcdir)/src/math/i386/remquof.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/remquol.lo: $(srcdir)/src/math/i386/remquol.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbln.lo: $(srcdir)/src/math/i386/scalbln.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalblnf.lo: $(srcdir)/src/math/i386/scalblnf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalblnl.lo: $(srcdir)/src/math/i386/scalblnl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbn.lo: $(srcdir)/src/math/i386/scalbn.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbnf.lo: $(srcdir)/src/math/i386/scalbnf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/scalbnl.lo: $(srcdir)/src/math/i386/scalbnl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/trunc.lo: $(srcdir)/src/math/i386/trunc.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/truncf.lo: $(srcdir)/src/math/i386/truncf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/i386/truncl.lo: $(srcdir)/src/math/i386/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/__invtrigl.lo: $(srcdir)/src/math/x32/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/acosl.lo: $(srcdir)/src/math/x32/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/asinl.lo: $(srcdir)/src/math/x32/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/atan2l.lo: $(srcdir)/src/math/x32/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/atanl.lo: $(srcdir)/src/math/x32/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/ceill.lo: $(srcdir)/src/math/x32/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/exp2l.lo: $(srcdir)/src/math/x32/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/expl.lo: $(srcdir)/src/math/x32/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/expm1l.lo: $(srcdir)/src/math/x32/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabs.lo: $(srcdir)/src/math/x32/fabs.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabsf.lo: $(srcdir)/src/math/x32/fabsf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fabsl.lo: $(srcdir)/src/math/x32/fabsl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/floorl.lo: $(srcdir)/src/math/x32/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/fmodl.lo: $(srcdir)/src/math/x32/fmodl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrint.lo: $(srcdir)/src/math/x32/llrint.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrintf.lo: $(srcdir)/src/math/x32/llrintf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/llrintl.lo: $(srcdir)/src/math/x32/llrintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log10l.lo: $(srcdir)/src/math/x32/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log1pl.lo: $(srcdir)/src/math/x32/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/log2l.lo: $(srcdir)/src/math/x32/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/logl.lo: $(srcdir)/src/math/x32/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrint.lo: $(srcdir)/src/math/x32/lrint.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrintf.lo: $(srcdir)/src/math/x32/lrintf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/lrintl.lo: $(srcdir)/src/math/x32/lrintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/remainderl.lo: $(srcdir)/src/math/x32/remainderl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/rintl.lo: $(srcdir)/src/math/x32/rintl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrt.lo: $(srcdir)/src/math/x32/sqrt.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrtf.lo: $(srcdir)/src/math/x32/sqrtf.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/sqrtl.lo: $(srcdir)/src/math/x32/sqrtl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x32/truncl.lo: $(srcdir)/src/math/x32/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/__invtrigl.lo: $(srcdir)/src/math/x86_64/__invtrigl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/acosl.lo: $(srcdir)/src/math/x86_64/acosl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/asinl.lo: $(srcdir)/src/math/x86_64/asinl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/atan2l.lo: $(srcdir)/src/math/x86_64/atan2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/atanl.lo: $(srcdir)/src/math/x86_64/atanl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/ceill.lo: $(srcdir)/src/math/x86_64/ceill.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/exp2l.lo: $(srcdir)/src/math/x86_64/exp2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/expl.lo: $(srcdir)/src/math/x86_64/expl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/expm1l.lo: $(srcdir)/src/math/x86_64/expm1l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/floorl.lo: $(srcdir)/src/math/x86_64/floorl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log10l.lo: $(srcdir)/src/math/x86_64/log10l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log1pl.lo: $(srcdir)/src/math/x86_64/log1pl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/log2l.lo: $(srcdir)/src/math/x86_64/log2l.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/logl.lo: $(srcdir)/src/math/x86_64/logl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/math/x86_64/truncl.lo: $(srcdir)/src/math/x86_64/truncl.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/aarch64/vfork.lo: $(srcdir)/src/process/aarch64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/arm/vfork.lo: $(srcdir)/src/process/arm/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/i386/vfork.lo: $(srcdir)/src/process/i386/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/riscv64/vfork.lo: $(srcdir)/src/process/riscv64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/s390x/vfork.lo: $(srcdir)/src/process/s390x/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/sh/vfork.lo: $(srcdir)/src/process/sh/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/x32/vfork.lo: $(srcdir)/src/process/x32/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/process/x86_64/vfork.lo: $(srcdir)/src/process/x86_64/vfork.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/aarch64/longjmp.lo: $(srcdir)/src/setjmp/aarch64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/aarch64/setjmp.lo: $(srcdir)/src/setjmp/aarch64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/i386/longjmp.lo: $(srcdir)/src/setjmp/i386/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/i386/setjmp.lo: $(srcdir)/src/setjmp/i386/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/m68k/longjmp.lo: $(srcdir)/src/setjmp/m68k/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/m68k/setjmp.lo: $(srcdir)/src/setjmp/m68k/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/microblaze/longjmp.lo: \
  $(srcdir)/src/setjmp/microblaze/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/microblaze/setjmp.lo: $(srcdir)/src/setjmp/microblaze/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/or1k/longjmp.lo: $(srcdir)/src/setjmp/or1k/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/or1k/setjmp.lo: $(srcdir)/src/setjmp/or1k/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/powerpc64/longjmp.lo: $(srcdir)/src/setjmp/powerpc64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/powerpc64/setjmp.lo: $(srcdir)/src/setjmp/powerpc64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/s390x/longjmp.lo: $(srcdir)/src/setjmp/s390x/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/s390x/setjmp.lo: $(srcdir)/src/setjmp/s390x/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x32/longjmp.lo: $(srcdir)/src/setjmp/x32/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x32/setjmp.lo: $(srcdir)/src/setjmp/x32/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x86_64/longjmp.lo: $(srcdir)/src/setjmp/x86_64/longjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/setjmp/x86_64/setjmp.lo: $(srcdir)/src/setjmp/x86_64/setjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/aarch64/restore.lo: $(srcdir)/src/signal/aarch64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/aarch64/sigsetjmp.lo: $(srcdir)/src/signal/aarch64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/arm/restore.lo: $(srcdir)/src/signal/arm/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/arm/sigsetjmp.lo: $(srcdir)/src/signal/arm/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/i386/restore.lo: $(srcdir)/src/signal/i386/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/i386/sigsetjmp.lo: $(srcdir)/src/signal/i386/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/loongarch64/restore.lo: \
  $(srcdir)/src/signal/loongarch64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/loongarch64/sigsetjmp.lo: \
  $(srcdir)/src/signal/loongarch64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/m68k/sigsetjmp.lo: $(srcdir)/src/signal/m68k/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/microblaze/restore.lo: \
  $(srcdir)/src/signal/microblaze/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/microblaze/sigsetjmp.lo: \
  $(srcdir)/src/signal/microblaze/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mips/sigsetjmp.lo: $(srcdir)/src/signal/mips/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mips64/sigsetjmp.lo: $(srcdir)/src/signal/mips64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/mipsn32/sigsetjmp.lo: $(srcdir)/src/signal/mipsn32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/or1k/sigsetjmp.lo: $(srcdir)/src/signal/or1k/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc/restore.lo: $(srcdir)/src/signal/powerpc/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc/sigsetjmp.lo: $(srcdir)/src/signal/powerpc/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc64/restore.lo: $(srcdir)/src/signal/powerpc64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/powerpc64/sigsetjmp.lo: \
  $(srcdir)/src/signal/powerpc64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv32/restore.lo: $(srcdir)/src/signal/riscv32/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv32/sigsetjmp.lo: $(srcdir)/src/signal/riscv32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv64/restore.lo: $(srcdir)/src/signal/riscv64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/riscv64/sigsetjmp.lo: $(srcdir)/src/signal/riscv64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/s390x/restore.lo: $(srcdir)/src/signal/s390x/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/s390x/sigsetjmp.lo: $(srcdir)/src/signal/s390x/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/sh/restore.lo: $(srcdir)/src/signal/sh/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/sh/sigsetjmp.lo: $(srcdir)/src/signal/sh/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x32/restore.lo: $(srcdir)/src/signal/x32/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x32/sigsetjmp.lo: $(srcdir)/src/signal/x32/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x86_64/restore.lo: $(srcdir)/src/signal/x86_64/restore.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/signal/x86_64/sigsetjmp.lo: $(srcdir)/src/signal/x86_64/sigsetjmp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/arm/__aeabi_memcpy.lo: \
  $(srcdir)/src/string/arm/__aeabi_memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/arm/__aeabi_memset.lo: \
  $(srcdir)/src/string/arm/__aeabi_memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memcpy.lo: $(srcdir)/src/string/i386/memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memmove.lo: $(srcdir)/src/string/i386/memmove.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/i386/memset.lo: $(srcdir)/src/string/i386/memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memcpy.lo: $(srcdir)/src/string/x86_64/memcpy.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memmove.lo: $(srcdir)/src/string/x86_64/memmove.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/string/x86_64/memset.lo: $(srcdir)/src/string/x86_64/memset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/__unmapself.lo: \
  $(srcdir)/src/thread/aarch64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/clone.lo: $(srcdir)/src/thread/aarch64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/aarch64/syscall_cp.lo: \
  $(srcdir)/src/thread/aarch64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/__aeabi_read_tp.lo: \
  $(srcdir)/src/thread/arm/__aeabi_read_tp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/__unmapself.lo: $(srcdir)/src/thread/arm/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/atomics.lo: $(srcdir)/src/thread/arm/atomics.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/clone.lo: $(srcdir)/src/thread/arm/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/arm/syscall_cp.lo: $(srcdir)/src/thread/arm/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/__set_thread_area.lo: \
  $(srcdir)/src/thread/i386/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/__unmapself.lo: $(srcdir)/src/thread/i386/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/clone.lo: $(srcdir)/src/thread/i386/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/syscall_cp.lo: $(srcdir)/src/thread/i386/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/i386/tls.lo: $(srcdir)/src/thread/i386/tls.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/__set_thread_area.lo: \
  $(srcdir)/src/thread/loongarch64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/__unmapself.lo: \
  $(srcdir)/src/thread/loongarch64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/clone.lo: $(srcdir)/src/thread/loongarch64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/loongarch64/syscall_cp.lo: \
  $(srcdir)/src/thread/loongarch64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/__m68k_read_tp.lo: \
  $(srcdir)/src/thread/m68k/__m68k_read_tp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/clone.lo: $(srcdir)/src/thread/m68k/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/m68k/syscall_cp.lo: $(srcdir)/src/thread/m68k/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/__set_thread_area.lo: \
  $(srcdir)/src/thread/microblaze/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/__unmapself.lo: \
  $(srcdir)/src/thread/microblaze/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/clone.lo: $(srcdir)/src/thread/microblaze/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/microblaze/syscall_cp.lo: \
  $(srcdir)/src/thread/microblaze/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/__unmapself.lo: $(srcdir)/src/thread/mips/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/clone.lo: $(srcdir)/src/thread/mips/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips/syscall_cp.lo: $(srcdir)/src/thread/mips/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/__unmapself.lo: \
  $(srcdir)/src/thread/mips64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/clone.lo: $(srcdir)/src/thread/mips64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mips64/syscall_cp.lo: $(srcdir)/src/thread/mips64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/__unmapself.lo: \
  $(srcdir)/src/thread/mipsn32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/clone.lo: $(srcdir)/src/thread/mipsn32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/mipsn32/syscall_cp.lo: \
  $(srcdir)/src/thread/mipsn32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/__set_thread_area.lo: \
  $(srcdir)/src/thread/or1k/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/__unmapself.lo: $(srcdir)/src/thread/or1k/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/clone.lo: $(srcdir)/src/thread/or1k/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/or1k/syscall_cp.lo: $(srcdir)/src/thread/or1k/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/__set_thread_area.lo: \
  $(srcdir)/src/thread/powerpc/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/__unmapself.lo: \
  $(srcdir)/src/thread/powerpc/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/clone.lo: $(srcdir)/src/thread/powerpc/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc/syscall_cp.lo: \
  $(srcdir)/src/thread/powerpc/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/__set_thread_area.lo: \
  $(srcdir)/src/thread/powerpc64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/__unmapself.lo: \
  $(srcdir)/src/thread/powerpc64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/clone.lo: $(srcdir)/src/thread/powerpc64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/powerpc64/syscall_cp.lo: \
  $(srcdir)/src/thread/powerpc64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/__set_thread_area.lo: \
  $(srcdir)/src/thread/riscv32/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/__unmapself.lo: \
  $(srcdir)/src/thread/riscv32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/clone.lo: $(srcdir)/src/thread/riscv32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv32/syscall_cp.lo: \
  $(srcdir)/src/thread/riscv32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/__set_thread_area.lo: \
  $(srcdir)/src/thread/riscv64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/__unmapself.lo: \
  $(srcdir)/src/thread/riscv64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/clone.lo: $(srcdir)/src/thread/riscv64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/riscv64/syscall_cp.lo: \
  $(srcdir)/src/thread/riscv64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__set_thread_area.lo: \
  $(srcdir)/src/thread/s390x/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__unmapself.lo: $(srcdir)/src/thread/s390x/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/__tls_get_offset.lo: \
  $(srcdir)/src/thread/s390x/__tls_get_offset.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/clone.lo: $(srcdir)/src/thread/s390x/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/s390x/syscall_cp.lo: $(srcdir)/src/thread/s390x/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/__unmapself_mmu.lo: \
  $(srcdir)/src/thread/sh/__unmapself_mmu.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/atomics.lo: $(srcdir)/src/thread/sh/atomics.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/clone.lo: $(srcdir)/src/thread/sh/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/sh/syscall_cp.lo: $(srcdir)/src/thread/sh/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/__set_thread_area.lo: \
  $(srcdir)/src/thread/x32/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/__unmapself.lo: $(srcdir)/src/thread/x32/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/clone.lo: $(srcdir)/src/thread/x32/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x32/syscall_cp.lo: $(srcdir)/src/thread/x32/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/__set_thread_area.lo: \
  $(srcdir)/src/thread/x86_64/__set_thread_area.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/__unmapself.lo: \
  $(srcdir)/src/thread/x86_64/__unmapself.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/clone.lo: $(srcdir)/src/thread/x86_64/clone.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/thread/x86_64/syscall_cp.lo: $(srcdir)/src/thread/x86_64/syscall_cp.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mips/pipe.lo: $(srcdir)/src/unistd/mips/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mips64/pipe.lo: $(srcdir)/src/unistd/mips64/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/mipsn32/pipe.lo: $(srcdir)/src/unistd/mipsn32/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi
$(objbuilddir)/src/unistd/sh/pipe.lo: $(srcdir)/src/unistd/sh/pipe.s
	@if [ "$(ADD_CFI)" = "yes" ]; then $(AS_CMD0) $< | $(AS_CMD1) $@ -; \
	else $(CC_CMD) $@ $<; fi

$(objbuilddir)/src/fenv/arm/fenv-hf.lo: $(srcdir)/src/fenv/arm/fenv-hf.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/loongarch64/fenv.lo: $(srcdir)/src/fenv/loongarch64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips/fenv.lo: $(srcdir)/src/fenv/mips/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips64/fenv.lo: $(srcdir)/src/fenv/mips64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mipsn32/fenv.lo: $(srcdir)/src/fenv/mipsn32/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc/fenv.lo: $(srcdir)/src/fenv/powerpc/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv32/fenv.lo: $(srcdir)/src/fenv/riscv32/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv64/fenv.lo: $(srcdir)/src/fenv/riscv64/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/sh/fenv.lo: $(srcdir)/src/fenv/sh/fenv.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/dlsym_time64.lo: $(srcdir)/src/ldso/arm/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/tlsdesc.lo: $(srcdir)/src/ldso/arm/tlsdesc.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/i386/dlsym_time64.lo: $(srcdir)/src/ldso/i386/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/m68k/dlsym_time64.lo: $(srcdir)/src/ldso/m68k/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/microblaze/dlsym_time64.lo: \
  $(srcdir)/src/ldso/microblaze/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/mips/dlsym_time64.lo: $(srcdir)/src/ldso/mips/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/mipsn32/dlsym_time64.lo: \
  $(srcdir)/src/ldso/mipsn32/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/or1k/dlsym_time64.lo: $(srcdir)/src/ldso/or1k/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/powerpc/dlsym_time64.lo: \
  $(srcdir)/src/ldso/powerpc/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/sh/dlsym_time64.lo: $(srcdir)/src/ldso/sh/dlsym_time64.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/arm/longjmp.lo: $(srcdir)/src/setjmp/arm/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/arm/setjmp.lo: $(srcdir)/src/setjmp/arm/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/loongarch64/longjmp.lo: \
  $(srcdir)/src/setjmp/loongarch64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/loongarch64/setjmp.lo: \
  $(srcdir)/src/setjmp/loongarch64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips/longjmp.lo: $(srcdir)/src/setjmp/mips/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips/setjmp.lo: $(srcdir)/src/setjmp/mips/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips64/longjmp.lo: $(srcdir)/src/setjmp/mips64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mips64/setjmp.lo: $(srcdir)/src/setjmp/mips64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mipsn32/longjmp.lo: $(srcdir)/src/setjmp/mipsn32/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/mipsn32/setjmp.lo: $(srcdir)/src/setjmp/mipsn32/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/powerpc/longjmp.lo: $(srcdir)/src/setjmp/powerpc/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/powerpc/setjmp.lo: $(srcdir)/src/setjmp/powerpc/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv32/longjmp.lo: $(srcdir)/src/setjmp/riscv32/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv32/setjmp.lo: $(srcdir)/src/setjmp/riscv32/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv64/longjmp.lo: $(srcdir)/src/setjmp/riscv64/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/riscv64/setjmp.lo: $(srcdir)/src/setjmp/riscv64/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/sh/longjmp.lo: $(srcdir)/src/setjmp/sh/longjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/sh/setjmp.lo: $(srcdir)/src/setjmp/sh/setjmp.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/aarch64/memcpy.lo: $(srcdir)/src/string/aarch64/memcpy.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/aarch64/memset.lo: $(srcdir)/src/string/aarch64/memset.S
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/arm/memcpy.lo: $(srcdir)/src/string/arm/memcpy.S
	$(CC_CMD) $@ $<

$(objbuilddir)/compat/time32/__xstat.lo: $(srcdir)/compat/time32/__xstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/adjtime32.lo: $(srcdir)/compat/time32/adjtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/adjtimex_time32.lo: \
  $(srcdir)/compat/time32/adjtimex_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/aio_suspend_time32.lo: \
  $(srcdir)/compat/time32/aio_suspend_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_adjtime32.lo: \
  $(srcdir)/compat/time32/clock_adjtime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_getres_time32.lo: \
  $(srcdir)/compat/time32/clock_getres_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_gettime32.lo: \
  $(srcdir)/compat/time32/clock_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_nanosleep_time32.lo: \
  $(srcdir)/compat/time32/clock_nanosleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/clock_settime32.lo: \
  $(srcdir)/compat/time32/clock_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/cnd_timedwait_time32.lo: \
  $(srcdir)/compat/time32/cnd_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ctime32.lo: $(srcdir)/compat/time32/ctime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ctime32_r.lo: $(srcdir)/compat/time32/ctime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/difftime32.lo: $(srcdir)/compat/time32/difftime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/fstat_time32.lo: $(srcdir)/compat/time32/fstat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/fstatat_time32.lo: $(srcdir)/compat/time32/fstatat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ftime32.lo: $(srcdir)/compat/time32/ftime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimens_time32.lo: \
  $(srcdir)/compat/time32/futimens_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimes_time32.lo: $(srcdir)/compat/time32/futimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/futimesat_time32.lo: \
  $(srcdir)/compat/time32/futimesat_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/getitimer_time32.lo: \
  $(srcdir)/compat/time32/getitimer_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/getrusage_time32.lo: \
  $(srcdir)/compat/time32/getrusage_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gettimeofday_time32.lo: \
  $(srcdir)/compat/time32/gettimeofday_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gmtime32.lo: $(srcdir)/compat/time32/gmtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/gmtime32_r.lo: $(srcdir)/compat/time32/gmtime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/localtime32.lo: $(srcdir)/compat/time32/localtime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/localtime32_r.lo: $(srcdir)/compat/time32/localtime32_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/lstat_time32.lo: $(srcdir)/compat/time32/lstat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/lutimes_time32.lo: $(srcdir)/compat/time32/lutimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mktime32.lo: $(srcdir)/compat/time32/mktime32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mq_timedreceive_time32.lo: \
  $(srcdir)/compat/time32/mq_timedreceive_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mq_timedsend_time32.lo: \
  $(srcdir)/compat/time32/mq_timedsend_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/mtx_timedlock_time32.lo: \
  $(srcdir)/compat/time32/mtx_timedlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/nanosleep_time32.lo: \
  $(srcdir)/compat/time32/nanosleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/ppoll_time32.lo: $(srcdir)/compat/time32/ppoll_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pselect_time32.lo: $(srcdir)/compat/time32/pselect_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_cond_timedwait_time32.lo: \
  $(srcdir)/compat/time32/pthread_cond_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_mutex_timedlock_time32.lo: \
  $(srcdir)/compat/time32/pthread_mutex_timedlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_rwlock_timedrdlock_time32.lo: \
  $(srcdir)/compat/time32/pthread_rwlock_timedrdlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_rwlock_timedwrlock_time32.lo: \
  $(srcdir)/compat/time32/pthread_rwlock_timedwrlock_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/pthread_timedjoin_np_time32.lo: \
  $(srcdir)/compat/time32/pthread_timedjoin_np_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/recvmmsg_time32.lo: \
  $(srcdir)/compat/time32/recvmmsg_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sched_rr_get_interval_time32.lo: \
  $(srcdir)/compat/time32/sched_rr_get_interval_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/select_time32.lo: $(srcdir)/compat/time32/select_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sem_timedwait_time32.lo: \
  $(srcdir)/compat/time32/sem_timedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/semtimedop_time32.lo: \
  $(srcdir)/compat/time32/semtimedop_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/setitimer_time32.lo: \
  $(srcdir)/compat/time32/setitimer_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/settimeofday_time32.lo: \
  $(srcdir)/compat/time32/settimeofday_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/sigtimedwait_time32.lo: \
  $(srcdir)/compat/time32/sigtimedwait_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/stat_time32.lo: $(srcdir)/compat/time32/stat_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/stime32.lo: $(srcdir)/compat/time32/stime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/thrd_sleep_time32.lo: \
  $(srcdir)/compat/time32/thrd_sleep_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/time32.lo: $(srcdir)/compat/time32/time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/time32gm.lo: $(srcdir)/compat/time32/time32gm.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timer_gettime32.lo: \
  $(srcdir)/compat/time32/timer_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timer_settime32.lo: \
  $(srcdir)/compat/time32/timer_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timerfd_gettime32.lo: \
  $(srcdir)/compat/time32/timerfd_gettime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timerfd_settime32.lo: \
  $(srcdir)/compat/time32/timerfd_settime32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/timespec_get_time32.lo: \
  $(srcdir)/compat/time32/timespec_get_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utime_time32.lo: $(srcdir)/compat/time32/utime_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utimensat_time32.lo: \
  $(srcdir)/compat/time32/utimensat_time32.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/utimes_time32.lo: $(srcdir)/compat/time32/utimes_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/wait3_time32.lo: $(srcdir)/compat/time32/wait3_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/compat/time32/wait4_time32.lo: $(srcdir)/compat/time32/wait4_time32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/Scrt1.lo: $(srcdir)/crt/Scrt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crt1.lo: $(srcdir)/crt/crt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crti.lo: $(srcdir)/crt/crti.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/crtn.lo: $(srcdir)/crt/crtn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/crt/rcrt1.lo: $(srcdir)/crt/rcrt1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/ldso/dlstart.lo: $(srcdir)/ldso/dlstart.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/ldso/dynlink.lo: $(srcdir)/ldso/dynlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/aio.lo: $(srcdir)/src/aio/aio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/aio_suspend.lo: $(srcdir)/src/aio/aio_suspend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/aio/lio_listio.lo: $(srcdir)/src/aio/lio_listio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/__cexp.lo: $(srcdir)/src/complex/__cexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/__cexpf.lo: $(srcdir)/src/complex/__cexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabs.lo: $(srcdir)/src/complex/cabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabsf.lo: $(srcdir)/src/complex/cabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cabsl.lo: $(srcdir)/src/complex/cabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacos.lo: $(srcdir)/src/complex/cacos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosf.lo: $(srcdir)/src/complex/cacosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosh.lo: $(srcdir)/src/complex/cacosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacoshf.lo: $(srcdir)/src/complex/cacoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacoshl.lo: $(srcdir)/src/complex/cacoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cacosl.lo: $(srcdir)/src/complex/cacosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/carg.lo: $(srcdir)/src/complex/carg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cargf.lo: $(srcdir)/src/complex/cargf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cargl.lo: $(srcdir)/src/complex/cargl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casin.lo: $(srcdir)/src/complex/casin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinf.lo: $(srcdir)/src/complex/casinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinh.lo: $(srcdir)/src/complex/casinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinhf.lo: $(srcdir)/src/complex/casinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinhl.lo: $(srcdir)/src/complex/casinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/casinl.lo: $(srcdir)/src/complex/casinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catan.lo: $(srcdir)/src/complex/catan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanf.lo: $(srcdir)/src/complex/catanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanh.lo: $(srcdir)/src/complex/catanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanhf.lo: $(srcdir)/src/complex/catanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanhl.lo: $(srcdir)/src/complex/catanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/catanl.lo: $(srcdir)/src/complex/catanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccos.lo: $(srcdir)/src/complex/ccos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosf.lo: $(srcdir)/src/complex/ccosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosh.lo: $(srcdir)/src/complex/ccosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccoshf.lo: $(srcdir)/src/complex/ccoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccoshl.lo: $(srcdir)/src/complex/ccoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ccosl.lo: $(srcdir)/src/complex/ccosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexp.lo: $(srcdir)/src/complex/cexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexpf.lo: $(srcdir)/src/complex/cexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cexpl.lo: $(srcdir)/src/complex/cexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimag.lo: $(srcdir)/src/complex/cimag.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimagf.lo: $(srcdir)/src/complex/cimagf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cimagl.lo: $(srcdir)/src/complex/cimagl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clog.lo: $(srcdir)/src/complex/clog.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clogf.lo: $(srcdir)/src/complex/clogf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/clogl.lo: $(srcdir)/src/complex/clogl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conj.lo: $(srcdir)/src/complex/conj.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conjf.lo: $(srcdir)/src/complex/conjf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/conjl.lo: $(srcdir)/src/complex/conjl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpow.lo: $(srcdir)/src/complex/cpow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpowf.lo: $(srcdir)/src/complex/cpowf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cpowl.lo: $(srcdir)/src/complex/cpowl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cproj.lo: $(srcdir)/src/complex/cproj.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cprojf.lo: $(srcdir)/src/complex/cprojf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/cprojl.lo: $(srcdir)/src/complex/cprojl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/creal.lo: $(srcdir)/src/complex/creal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/crealf.lo: $(srcdir)/src/complex/crealf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/creall.lo: $(srcdir)/src/complex/creall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csin.lo: $(srcdir)/src/complex/csin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinf.lo: $(srcdir)/src/complex/csinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinh.lo: $(srcdir)/src/complex/csinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinhf.lo: $(srcdir)/src/complex/csinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinhl.lo: $(srcdir)/src/complex/csinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csinl.lo: $(srcdir)/src/complex/csinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrt.lo: $(srcdir)/src/complex/csqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrtf.lo: $(srcdir)/src/complex/csqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/csqrtl.lo: $(srcdir)/src/complex/csqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctan.lo: $(srcdir)/src/complex/ctan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanf.lo: $(srcdir)/src/complex/ctanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanh.lo: $(srcdir)/src/complex/ctanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanhf.lo: $(srcdir)/src/complex/ctanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanhl.lo: $(srcdir)/src/complex/ctanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/complex/ctanl.lo: $(srcdir)/src/complex/ctanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/confstr.lo: $(srcdir)/src/conf/confstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/legacy.lo: $(srcdir)/src/conf/legacy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/fpathconf.lo: $(srcdir)/src/conf/fpathconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/pathconf.lo: $(srcdir)/src/conf/pathconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/conf/sysconf.lo: $(srcdir)/src/conf/sysconf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt.lo: $(srcdir)/src/crypt/crypt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_blowfish.lo: $(srcdir)/src/crypt/crypt_blowfish.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_des.lo: $(srcdir)/src/crypt/crypt_des.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_md5.lo: $(srcdir)/src/crypt/crypt_md5.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_r.lo: $(srcdir)/src/crypt/crypt_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_sha256.lo: $(srcdir)/src/crypt/crypt_sha256.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/crypt_sha512.lo: $(srcdir)/src/crypt/crypt_sha512.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/crypt/encrypt.lo: $(srcdir)/src/crypt/encrypt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_b_loc.lo: $(srcdir)/src/ctype/__ctype_b_loc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_get_mb_cur_max.lo: \
  $(srcdir)/src/ctype/__ctype_get_mb_cur_max.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_tolower_loc.lo: \
  $(srcdir)/src/ctype/__ctype_tolower_loc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/__ctype_toupper_loc.lo: \
  $(srcdir)/src/ctype/__ctype_toupper_loc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isalnum.lo: $(srcdir)/src/ctype/isalnum.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isalpha.lo: $(srcdir)/src/ctype/isalpha.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isascii.lo: $(srcdir)/src/ctype/isascii.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isblank.lo: $(srcdir)/src/ctype/isblank.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iscntrl.lo: $(srcdir)/src/ctype/iscntrl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isdigit.lo: $(srcdir)/src/ctype/isdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isgraph.lo: $(srcdir)/src/ctype/isgraph.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/islower.lo: $(srcdir)/src/ctype/islower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isprint.lo: $(srcdir)/src/ctype/isprint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/ispunct.lo: $(srcdir)/src/ctype/ispunct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isspace.lo: $(srcdir)/src/ctype/isspace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isupper.lo: $(srcdir)/src/ctype/isupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswalnum.lo: $(srcdir)/src/ctype/iswalnum.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswalpha.lo: $(srcdir)/src/ctype/iswalpha.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswblank.lo: $(srcdir)/src/ctype/iswblank.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswcntrl.lo: $(srcdir)/src/ctype/iswcntrl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswctype.lo: $(srcdir)/src/ctype/iswctype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswdigit.lo: $(srcdir)/src/ctype/iswdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswgraph.lo: $(srcdir)/src/ctype/iswgraph.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswlower.lo: $(srcdir)/src/ctype/iswlower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswprint.lo: $(srcdir)/src/ctype/iswprint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswpunct.lo: $(srcdir)/src/ctype/iswpunct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswspace.lo: $(srcdir)/src/ctype/iswspace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswupper.lo: $(srcdir)/src/ctype/iswupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/iswxdigit.lo: $(srcdir)/src/ctype/iswxdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/isxdigit.lo: $(srcdir)/src/ctype/isxdigit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/toascii.lo: $(srcdir)/src/ctype/toascii.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/tolower.lo: $(srcdir)/src/ctype/tolower.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/toupper.lo: $(srcdir)/src/ctype/toupper.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/towctrans.lo: $(srcdir)/src/ctype/towctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wcswidth.lo: $(srcdir)/src/ctype/wcswidth.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wctrans.lo: $(srcdir)/src/ctype/wctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ctype/wcwidth.lo: $(srcdir)/src/ctype/wcwidth.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/alphasort.lo: $(srcdir)/src/dirent/alphasort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/closedir.lo: $(srcdir)/src/dirent/closedir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/dirfd.lo: $(srcdir)/src/dirent/dirfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/fdopendir.lo: $(srcdir)/src/dirent/fdopendir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/opendir.lo: $(srcdir)/src/dirent/opendir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/posix_getdents.lo: $(srcdir)/src/dirent/posix_getdents.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/readdir.lo: $(srcdir)/src/dirent/readdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/readdir_r.lo: $(srcdir)/src/dirent/readdir_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/rewinddir.lo: $(srcdir)/src/dirent/rewinddir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/scandir.lo: $(srcdir)/src/dirent/scandir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/seekdir.lo: $(srcdir)/src/dirent/seekdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/telldir.lo: $(srcdir)/src/dirent/telldir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/dirent/versionsort.lo: $(srcdir)/src/dirent/versionsort.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__environ.lo: $(srcdir)/src/env/__environ.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__init_tls.lo: $(srcdir)/src/env/__init_tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__libc_start_main.lo: $(srcdir)/src/env/__libc_start_main.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__reset_tls.lo: $(srcdir)/src/env/__reset_tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/__stack_chk_fail.lo: $(srcdir)/src/env/__stack_chk_fail.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/clearenv.lo: $(srcdir)/src/env/clearenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/getenv.lo: $(srcdir)/src/env/getenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/putenv.lo: $(srcdir)/src/env/putenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/secure_getenv.lo: $(srcdir)/src/env/secure_getenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/setenv.lo: $(srcdir)/src/env/setenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/env/unsetenv.lo: $(srcdir)/src/env/unsetenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/errno/__errno_location.lo: $(srcdir)/src/errno/__errno_location.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/errno/strerror.lo: $(srcdir)/src/errno/strerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/arm/__aeabi_atexit.lo: $(srcdir)/src/exit/arm/__aeabi_atexit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/_Exit.lo: $(srcdir)/src/exit/_Exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/abort.lo: $(srcdir)/src/exit/abort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/abort_lock.lo: $(srcdir)/src/exit/abort_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/assert.lo: $(srcdir)/src/exit/assert.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/at_quick_exit.lo: $(srcdir)/src/exit/at_quick_exit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/atexit.lo: $(srcdir)/src/exit/atexit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/exit.lo: $(srcdir)/src/exit/exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/exit/quick_exit.lo: $(srcdir)/src/exit/quick_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/creat.lo: $(srcdir)/src/fcntl/creat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/fcntl.lo: $(srcdir)/src/fcntl/fcntl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/open.lo: $(srcdir)/src/fcntl/open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/openat.lo: $(srcdir)/src/fcntl/openat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/posix_fadvise.lo: $(srcdir)/src/fcntl/posix_fadvise.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fcntl/posix_fallocate.lo: $(srcdir)/src/fcntl/posix_fallocate.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/__flt_rounds.lo: $(srcdir)/src/fenv/__flt_rounds.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fegetexceptflag.lo: $(srcdir)/src/fenv/fegetexceptflag.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/feholdexcept.lo: $(srcdir)/src/fenv/feholdexcept.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fenv.lo: $(srcdir)/src/fenv/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/arm/fenv.lo: $(srcdir)/src/fenv/arm/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/m68k/fenv.lo: $(srcdir)/src/fenv/m68k/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips/fenv-sf.lo: $(srcdir)/src/fenv/mips/fenv-sf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mips64/fenv-sf.lo: $(srcdir)/src/fenv/mips64/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/mipsn32/fenv-sf.lo: $(srcdir)/src/fenv/mipsn32/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc/fenv-sf.lo: $(srcdir)/src/fenv/powerpc/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/powerpc64/fenv.lo: $(srcdir)/src/fenv/powerpc64/fenv.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv32/fenv-sf.lo: $(srcdir)/src/fenv/riscv32/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/riscv64/fenv-sf.lo: $(srcdir)/src/fenv/riscv64/fenv-sf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/s390x/fenv.lo: $(srcdir)/src/fenv/s390x/fenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/sh/fenv-nofpu.lo: $(srcdir)/src/fenv/sh/fenv-nofpu.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fesetexceptflag.lo: $(srcdir)/src/fenv/fesetexceptflag.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/fesetround.lo: $(srcdir)/src/fenv/fesetround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/fenv/feupdateenv.lo: $(srcdir)/src/fenv/feupdateenv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/sh/__shcall.lo: $(srcdir)/src/internal/sh/__shcall.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/defsysinfo.lo: $(srcdir)/src/internal/defsysinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/emulate_wait4.lo: $(srcdir)/src/internal/emulate_wait4.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/floatscan.lo: $(srcdir)/src/internal/floatscan.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/intscan.lo: $(srcdir)/src/internal/intscan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/libc.lo: $(srcdir)/src/internal/libc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/procfdname.lo: $(srcdir)/src/internal/procfdname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/shgetc.lo: $(srcdir)/src/internal/shgetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/syscall_ret.lo: $(srcdir)/src/internal/syscall_ret.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/version.lo: $(srcdir)/src/internal/version.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/internal/vdso.lo: $(srcdir)/src/internal/vdso.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/ftok.lo: $(srcdir)/src/ipc/ftok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgctl.lo: $(srcdir)/src/ipc/msgctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgget.lo: $(srcdir)/src/ipc/msgget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgrcv.lo: $(srcdir)/src/ipc/msgrcv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/msgsnd.lo: $(srcdir)/src/ipc/msgsnd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semctl.lo: $(srcdir)/src/ipc/semctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semget.lo: $(srcdir)/src/ipc/semget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semop.lo: $(srcdir)/src/ipc/semop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/semtimedop.lo: $(srcdir)/src/ipc/semtimedop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmat.lo: $(srcdir)/src/ipc/shmat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmctl.lo: $(srcdir)/src/ipc/shmctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmdt.lo: $(srcdir)/src/ipc/shmdt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ipc/shmget.lo: $(srcdir)/src/ipc/shmget.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/__dlsym.lo: $(srcdir)/src/ldso/__dlsym.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dl_iterate_phdr.lo: $(srcdir)/src/ldso/dl_iterate_phdr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dladdr.lo: $(srcdir)/src/ldso/dladdr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlclose.lo: $(srcdir)/src/ldso/dlclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlerror.lo: $(srcdir)/src/ldso/dlerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlinfo.lo: $(srcdir)/src/ldso/dlinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlopen.lo: $(srcdir)/src/ldso/dlopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/dlsym.lo: $(srcdir)/src/ldso/dlsym.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/arm/find_exidx.lo: $(srcdir)/src/ldso/arm/find_exidx.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/ldso/tlsdesc.lo: $(srcdir)/src/ldso/tlsdesc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/cuserid.lo: $(srcdir)/src/legacy/cuserid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/daemon.lo: $(srcdir)/src/legacy/daemon.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/err.lo: $(srcdir)/src/legacy/err.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/euidaccess.lo: $(srcdir)/src/legacy/euidaccess.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/ftw.lo: $(srcdir)/src/legacy/ftw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/futimes.lo: $(srcdir)/src/legacy/futimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getdtablesize.lo: $(srcdir)/src/legacy/getdtablesize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getloadavg.lo: $(srcdir)/src/legacy/getloadavg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getpagesize.lo: $(srcdir)/src/legacy/getpagesize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getpass.lo: $(srcdir)/src/legacy/getpass.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/getusershell.lo: $(srcdir)/src/legacy/getusershell.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/isastream.lo: $(srcdir)/src/legacy/isastream.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/lutimes.lo: $(srcdir)/src/legacy/lutimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/ulimit.lo: $(srcdir)/src/legacy/ulimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/utmpx.lo: $(srcdir)/src/legacy/utmpx.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/legacy/valloc.lo: $(srcdir)/src/legacy/valloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/adjtime.lo: $(srcdir)/src/linux/adjtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/adjtimex.lo: $(srcdir)/src/linux/adjtimex.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/arch_prctl.lo: $(srcdir)/src/linux/arch_prctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/brk.lo: $(srcdir)/src/linux/brk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/cache.lo: $(srcdir)/src/linux/cache.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/cap.lo: $(srcdir)/src/linux/cap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/chroot.lo: $(srcdir)/src/linux/chroot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/clock_adjtime.lo: $(srcdir)/src/linux/clock_adjtime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/clone.lo: $(srcdir)/src/linux/clone.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/copy_file_range.lo: $(srcdir)/src/linux/copy_file_range.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/epoll.lo: $(srcdir)/src/linux/epoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/eventfd.lo: $(srcdir)/src/linux/eventfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/fallocate.lo: $(srcdir)/src/linux/fallocate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/fanotify.lo: $(srcdir)/src/linux/fanotify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/flock.lo: $(srcdir)/src/linux/flock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/getdents.lo: $(srcdir)/src/linux/getdents.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/getrandom.lo: $(srcdir)/src/linux/getrandom.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/gettid.lo: $(srcdir)/src/linux/gettid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/inotify.lo: $(srcdir)/src/linux/inotify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/ioperm.lo: $(srcdir)/src/linux/ioperm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/iopl.lo: $(srcdir)/src/linux/iopl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/klogctl.lo: $(srcdir)/src/linux/klogctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/membarrier.lo: $(srcdir)/src/linux/membarrier.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/memfd_create.lo: $(srcdir)/src/linux/memfd_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/mlock2.lo: $(srcdir)/src/linux/mlock2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/module.lo: $(srcdir)/src/linux/module.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/mount.lo: $(srcdir)/src/linux/mount.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/name_to_handle_at.lo: $(srcdir)/src/linux/name_to_handle_at.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/open_by_handle_at.lo: $(srcdir)/src/linux/open_by_handle_at.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/personality.lo: $(srcdir)/src/linux/personality.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/pivot_root.lo: $(srcdir)/src/linux/pivot_root.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/prctl.lo: $(srcdir)/src/linux/prctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/preadv2.lo: $(srcdir)/src/linux/preadv2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/prlimit.lo: $(srcdir)/src/linux/prlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/process_vm.lo: $(srcdir)/src/linux/process_vm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/ptrace.lo: $(srcdir)/src/linux/ptrace.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/pwritev2.lo: $(srcdir)/src/linux/pwritev2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/quotactl.lo: $(srcdir)/src/linux/quotactl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/readahead.lo: $(srcdir)/src/linux/readahead.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/reboot.lo: $(srcdir)/src/linux/reboot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/remap_file_pages.lo: $(srcdir)/src/linux/remap_file_pages.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/renameat2.lo: $(srcdir)/src/linux/renameat2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sbrk.lo: $(srcdir)/src/linux/sbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sendfile.lo: $(srcdir)/src/linux/sendfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setfsgid.lo: $(srcdir)/src/linux/setfsgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setfsuid.lo: $(srcdir)/src/linux/setfsuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setgroups.lo: $(srcdir)/src/linux/setgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sethostname.lo: $(srcdir)/src/linux/sethostname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/setns.lo: $(srcdir)/src/linux/setns.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/settimeofday.lo: $(srcdir)/src/linux/settimeofday.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/signalfd.lo: $(srcdir)/src/linux/signalfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/splice.lo: $(srcdir)/src/linux/splice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/statx.lo: $(srcdir)/src/linux/statx.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/stime.lo: $(srcdir)/src/linux/stime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/swap.lo: $(srcdir)/src/linux/swap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sync_file_range.lo: $(srcdir)/src/linux/sync_file_range.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/syncfs.lo: $(srcdir)/src/linux/syncfs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/sysinfo.lo: $(srcdir)/src/linux/sysinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/x32/sysinfo.lo: $(srcdir)/src/linux/x32/sysinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/tee.lo: $(srcdir)/src/linux/tee.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/timerfd.lo: $(srcdir)/src/linux/timerfd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/unshare.lo: $(srcdir)/src/linux/unshare.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/utimes.lo: $(srcdir)/src/linux/utimes.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/vhangup.lo: $(srcdir)/src/linux/vhangup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/vmsplice.lo: $(srcdir)/src/linux/vmsplice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/wait3.lo: $(srcdir)/src/linux/wait3.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/wait4.lo: $(srcdir)/src/linux/wait4.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/linux/xattr.lo: $(srcdir)/src/linux/xattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/__lctrans.lo: $(srcdir)/src/locale/__lctrans.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/__mo_lookup.lo: $(srcdir)/src/locale/__mo_lookup.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/bind_textdomain_codeset.lo: \
  $(srcdir)/src/locale/bind_textdomain_codeset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/c_locale.lo: $(srcdir)/src/locale/c_locale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catclose.lo: $(srcdir)/src/locale/catclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catgets.lo: $(srcdir)/src/locale/catgets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/catopen.lo: $(srcdir)/src/locale/catopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/dcngettext.lo: $(srcdir)/src/locale/dcngettext.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/duplocale.lo: $(srcdir)/src/locale/duplocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/freelocale.lo: $(srcdir)/src/locale/freelocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/iconv.lo: $(srcdir)/src/locale/iconv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/iconv_close.lo: $(srcdir)/src/locale/iconv_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/langinfo.lo: $(srcdir)/src/locale/langinfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/locale_map.lo: $(srcdir)/src/locale/locale_map.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/localeconv.lo: $(srcdir)/src/locale/localeconv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/newlocale.lo: $(srcdir)/src/locale/newlocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/pleval.lo: $(srcdir)/src/locale/pleval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/setlocale.lo: $(srcdir)/src/locale/setlocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strcoll.lo: $(srcdir)/src/locale/strcoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strfmon.lo: $(srcdir)/src/locale/strfmon.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strtod_l.lo: $(srcdir)/src/locale/strtod_l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/strxfrm.lo: $(srcdir)/src/locale/strxfrm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/textdomain.lo: $(srcdir)/src/locale/textdomain.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/uselocale.lo: $(srcdir)/src/locale/uselocale.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/wcscoll.lo: $(srcdir)/src/locale/wcscoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/locale/wcsxfrm.lo: $(srcdir)/src/locale/wcsxfrm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/calloc.lo: $(srcdir)/src/malloc/calloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/free.lo: $(srcdir)/src/malloc/free.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/libc_calloc.lo: $(srcdir)/src/malloc/libc_calloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/lite_malloc.lo: $(srcdir)/src/malloc/lite_malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/aligned_alloc.lo: \
  $(srcdir)/src/malloc/mallocng/aligned_alloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/donate.lo: $(srcdir)/src/malloc/mallocng/donate.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/free.lo: $(srcdir)/src/malloc/mallocng/free.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/malloc.lo: $(srcdir)/src/malloc/mallocng/malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/malloc_usable_size.lo: \
  $(srcdir)/src/malloc/mallocng/malloc_usable_size.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/mallocng/realloc.lo: $(srcdir)/src/malloc/mallocng/realloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/memalign.lo: $(srcdir)/src/malloc/memalign.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/aligned_alloc.lo: \
  $(srcdir)/src/malloc/oldmalloc/aligned_alloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/malloc.lo: $(srcdir)/src/malloc/oldmalloc/malloc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/oldmalloc/malloc_usable_size.lo: \
  $(srcdir)/src/malloc/oldmalloc/malloc_usable_size.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/posix_memalign.lo: $(srcdir)/src/malloc/posix_memalign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/realloc.lo: $(srcdir)/src/malloc/realloc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/reallocarray.lo: $(srcdir)/src/malloc/reallocarray.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/malloc/replaced.lo: $(srcdir)/src/malloc/replaced.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cos.lo: $(srcdir)/src/math/__cos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cosdf.lo: $(srcdir)/src/math/__cosdf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__cosl.lo: $(srcdir)/src/math/__cosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__expo2.lo: $(srcdir)/src/math/__expo2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__expo2f.lo: $(srcdir)/src/math/__expo2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassify.lo: $(srcdir)/src/math/__fpclassify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassifyf.lo: $(srcdir)/src/math/__fpclassifyf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__fpclassifyl.lo: $(srcdir)/src/math/__fpclassifyl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__invtrigl.lo: $(srcdir)/src/math/__invtrigl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_divzero.lo: $(srcdir)/src/math/__math_divzero.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_divzerof.lo: $(srcdir)/src/math/__math_divzerof.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalid.lo: $(srcdir)/src/math/__math_invalid.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalidf.lo: $(srcdir)/src/math/__math_invalidf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_invalidl.lo: $(srcdir)/src/math/__math_invalidl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_oflow.lo: $(srcdir)/src/math/__math_oflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_oflowf.lo: $(srcdir)/src/math/__math_oflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_uflow.lo: $(srcdir)/src/math/__math_uflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_uflowf.lo: $(srcdir)/src/math/__math_uflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_xflow.lo: $(srcdir)/src/math/__math_xflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__math_xflowf.lo: $(srcdir)/src/math/__math_xflowf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__polevll.lo: $(srcdir)/src/math/__polevll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2.lo: $(srcdir)/src/math/__rem_pio2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2_large.lo: $(srcdir)/src/math/__rem_pio2_large.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2f.lo: $(srcdir)/src/math/__rem_pio2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__rem_pio2l.lo: $(srcdir)/src/math/__rem_pio2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbit.lo: $(srcdir)/src/math/__signbit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbitf.lo: $(srcdir)/src/math/__signbitf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__signbitl.lo: $(srcdir)/src/math/__signbitl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sin.lo: $(srcdir)/src/math/__sin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sindf.lo: $(srcdir)/src/math/__sindf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__sinl.lo: $(srcdir)/src/math/__sinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tan.lo: $(srcdir)/src/math/__tan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tandf.lo: $(srcdir)/src/math/__tandf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/__tanl.lo: $(srcdir)/src/math/__tanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acos.lo: $(srcdir)/src/math/acos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosf.lo: $(srcdir)/src/math/acosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosh.lo: $(srcdir)/src/math/acosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acoshf.lo: $(srcdir)/src/math/acoshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acoshl.lo: $(srcdir)/src/math/acoshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/acosl.lo: $(srcdir)/src/math/acosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asin.lo: $(srcdir)/src/math/asin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinf.lo: $(srcdir)/src/math/asinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinh.lo: $(srcdir)/src/math/asinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinhf.lo: $(srcdir)/src/math/asinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinhl.lo: $(srcdir)/src/math/asinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/asinl.lo: $(srcdir)/src/math/asinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan.lo: $(srcdir)/src/math/atan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2.lo: $(srcdir)/src/math/atan2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2f.lo: $(srcdir)/src/math/atan2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atan2l.lo: $(srcdir)/src/math/atan2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanf.lo: $(srcdir)/src/math/atanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanh.lo: $(srcdir)/src/math/atanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanhf.lo: $(srcdir)/src/math/atanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanhl.lo: $(srcdir)/src/math/atanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/atanl.lo: $(srcdir)/src/math/atanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrt.lo: $(srcdir)/src/math/cbrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrtf.lo: $(srcdir)/src/math/cbrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cbrtl.lo: $(srcdir)/src/math/cbrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceil.lo: $(srcdir)/src/math/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/ceil.lo: $(srcdir)/src/math/aarch64/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/ceil.lo: $(srcdir)/src/math/powerpc64/ceil.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceil.lo: $(srcdir)/src/math/s390x/ceil.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceilf.lo: $(srcdir)/src/math/ceilf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/ceilf.lo: $(srcdir)/src/math/aarch64/ceilf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/ceilf.lo: $(srcdir)/src/math/powerpc64/ceilf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceilf.lo: $(srcdir)/src/math/s390x/ceilf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ceill.lo: $(srcdir)/src/math/ceill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/ceill.lo: $(srcdir)/src/math/s390x/ceill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysign.lo: $(srcdir)/src/math/copysign.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/copysign.lo: $(srcdir)/src/math/riscv32/copysign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/copysign.lo: $(srcdir)/src/math/riscv64/copysign.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysignf.lo: $(srcdir)/src/math/copysignf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/copysignf.lo: $(srcdir)/src/math/riscv32/copysignf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/copysignf.lo: $(srcdir)/src/math/riscv64/copysignf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/copysignl.lo: $(srcdir)/src/math/copysignl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cos.lo: $(srcdir)/src/math/cos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosf.lo: $(srcdir)/src/math/cosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosh.lo: $(srcdir)/src/math/cosh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/coshf.lo: $(srcdir)/src/math/coshf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/coshl.lo: $(srcdir)/src/math/coshl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/cosl.lo: $(srcdir)/src/math/cosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erf.lo: $(srcdir)/src/math/erf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erff.lo: $(srcdir)/src/math/erff.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/erfl.lo: $(srcdir)/src/math/erfl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp.lo: $(srcdir)/src/math/exp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp_data.lo: $(srcdir)/src/math/exp_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10.lo: $(srcdir)/src/math/exp10.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10f.lo: $(srcdir)/src/math/exp10f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp10l.lo: $(srcdir)/src/math/exp10l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2.lo: $(srcdir)/src/math/exp2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2f.lo: $(srcdir)/src/math/exp2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2f_data.lo: $(srcdir)/src/math/exp2f_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/exp2l.lo: $(srcdir)/src/math/exp2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expf.lo: $(srcdir)/src/math/expf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expl.lo: $(srcdir)/src/math/expl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1.lo: $(srcdir)/src/math/expm1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1f.lo: $(srcdir)/src/math/expm1f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/expm1l.lo: $(srcdir)/src/math/expm1l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabs.lo: $(srcdir)/src/math/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fabs.lo: $(srcdir)/src/math/aarch64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fabs.lo: $(srcdir)/src/math/arm/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabs.lo: $(srcdir)/src/math/i386/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/fabs.lo: $(srcdir)/src/math/mips/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fabs.lo: $(srcdir)/src/math/powerpc/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fabs.lo: $(srcdir)/src/math/powerpc64/fabs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fabs.lo: $(srcdir)/src/math/riscv32/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fabs.lo: $(srcdir)/src/math/riscv64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabs.lo: $(srcdir)/src/math/s390x/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabs.lo: $(srcdir)/src/math/x86_64/fabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabsf.lo: $(srcdir)/src/math/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fabsf.lo: $(srcdir)/src/math/aarch64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fabsf.lo: $(srcdir)/src/math/arm/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabsf.lo: $(srcdir)/src/math/i386/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/fabsf.lo: $(srcdir)/src/math/mips/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fabsf.lo: $(srcdir)/src/math/powerpc/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fabsf.lo: $(srcdir)/src/math/powerpc64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fabsf.lo: $(srcdir)/src/math/riscv32/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fabsf.lo: $(srcdir)/src/math/riscv64/fabsf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabsf.lo: $(srcdir)/src/math/s390x/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabsf.lo: $(srcdir)/src/math/x86_64/fabsf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fabsl.lo: $(srcdir)/src/math/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fabsl.lo: $(srcdir)/src/math/i386/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fabsl.lo: $(srcdir)/src/math/s390x/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fabsl.lo: $(srcdir)/src/math/x86_64/fabsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdim.lo: $(srcdir)/src/math/fdim.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdimf.lo: $(srcdir)/src/math/fdimf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fdiml.lo: $(srcdir)/src/math/fdiml.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/finite.lo: $(srcdir)/src/math/finite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/finitef.lo: $(srcdir)/src/math/finitef.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floor.lo: $(srcdir)/src/math/floor.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/floor.lo: $(srcdir)/src/math/aarch64/floor.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/floor.lo: $(srcdir)/src/math/powerpc64/floor.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floor.lo: $(srcdir)/src/math/s390x/floor.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floorf.lo: $(srcdir)/src/math/floorf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/floorf.lo: $(srcdir)/src/math/aarch64/floorf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/floorf.lo: $(srcdir)/src/math/powerpc64/floorf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floorf.lo: $(srcdir)/src/math/s390x/floorf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/floorl.lo: $(srcdir)/src/math/floorl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/floorl.lo: $(srcdir)/src/math/s390x/floorl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fma.lo: $(srcdir)/src/math/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fma.lo: $(srcdir)/src/math/aarch64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fma.lo: $(srcdir)/src/math/arm/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fma.lo: $(srcdir)/src/math/powerpc/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fma.lo: $(srcdir)/src/math/powerpc64/fma.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fma.lo: $(srcdir)/src/math/riscv32/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fma.lo: $(srcdir)/src/math/riscv64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fma.lo: $(srcdir)/src/math/s390x/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x32/fma.lo: $(srcdir)/src/math/x32/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fma.lo: $(srcdir)/src/math/x86_64/fma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaf.lo: $(srcdir)/src/math/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmaf.lo: $(srcdir)/src/math/aarch64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/fmaf.lo: $(srcdir)/src/math/arm/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/fmaf.lo: $(srcdir)/src/math/powerpc/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmaf.lo: $(srcdir)/src/math/powerpc64/fmaf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmaf.lo: $(srcdir)/src/math/riscv32/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmaf.lo: $(srcdir)/src/math/riscv64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/fmaf.lo: $(srcdir)/src/math/s390x/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x32/fmaf.lo: $(srcdir)/src/math/x32/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fmaf.lo: $(srcdir)/src/math/x86_64/fmaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmal.lo: $(srcdir)/src/math/fmal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmax.lo: $(srcdir)/src/math/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmax.lo: $(srcdir)/src/math/aarch64/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmax.lo: $(srcdir)/src/math/powerpc64/fmax.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmax.lo: $(srcdir)/src/math/riscv32/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmax.lo: $(srcdir)/src/math/riscv64/fmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaxf.lo: $(srcdir)/src/math/fmaxf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmaxf.lo: $(srcdir)/src/math/aarch64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmaxf.lo: $(srcdir)/src/math/powerpc64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmaxf.lo: $(srcdir)/src/math/riscv32/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmaxf.lo: $(srcdir)/src/math/riscv64/fmaxf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmaxl.lo: $(srcdir)/src/math/fmaxl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmin.lo: $(srcdir)/src/math/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fmin.lo: $(srcdir)/src/math/aarch64/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fmin.lo: $(srcdir)/src/math/powerpc64/fmin.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fmin.lo: $(srcdir)/src/math/riscv32/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fmin.lo: $(srcdir)/src/math/riscv64/fmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fminf.lo: $(srcdir)/src/math/fminf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/fminf.lo: $(srcdir)/src/math/aarch64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/fminf.lo: $(srcdir)/src/math/powerpc64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/fminf.lo: $(srcdir)/src/math/riscv32/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/fminf.lo: $(srcdir)/src/math/riscv64/fminf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fminl.lo: $(srcdir)/src/math/fminl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmod.lo: $(srcdir)/src/math/fmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmod.lo: $(srcdir)/src/math/i386/fmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmodf.lo: $(srcdir)/src/math/fmodf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmodf.lo: $(srcdir)/src/math/i386/fmodf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/fmodl.lo: $(srcdir)/src/math/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/fmodl.lo: $(srcdir)/src/math/i386/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/fmodl.lo: $(srcdir)/src/math/x86_64/fmodl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexp.lo: $(srcdir)/src/math/frexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexpf.lo: $(srcdir)/src/math/frexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/frexpl.lo: $(srcdir)/src/math/frexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypot.lo: $(srcdir)/src/math/hypot.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypotf.lo: $(srcdir)/src/math/hypotf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/hypotl.lo: $(srcdir)/src/math/hypotl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogb.lo: $(srcdir)/src/math/ilogb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogbf.lo: $(srcdir)/src/math/ilogbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ilogbl.lo: $(srcdir)/src/math/ilogbl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j0.lo: $(srcdir)/src/math/j0.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j0f.lo: $(srcdir)/src/math/j0f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j1.lo: $(srcdir)/src/math/j1.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/j1f.lo: $(srcdir)/src/math/j1f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/jn.lo: $(srcdir)/src/math/jn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/jnf.lo: $(srcdir)/src/math/jnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexp.lo: $(srcdir)/src/math/ldexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexpf.lo: $(srcdir)/src/math/ldexpf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/ldexpl.lo: $(srcdir)/src/math/ldexpl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgamma.lo: $(srcdir)/src/math/lgamma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgamma_r.lo: $(srcdir)/src/math/lgamma_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammaf.lo: $(srcdir)/src/math/lgammaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammaf_r.lo: $(srcdir)/src/math/lgammaf_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lgammal.lo: $(srcdir)/src/math/lgammal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrint.lo: $(srcdir)/src/math/llrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llrint.lo: $(srcdir)/src/math/aarch64/llrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrint.lo: $(srcdir)/src/math/i386/llrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrint.lo: $(srcdir)/src/math/x86_64/llrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrintf.lo: $(srcdir)/src/math/llrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llrintf.lo: $(srcdir)/src/math/aarch64/llrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrintf.lo: $(srcdir)/src/math/i386/llrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrintf.lo: $(srcdir)/src/math/x86_64/llrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llrintl.lo: $(srcdir)/src/math/llrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/llrintl.lo: $(srcdir)/src/math/i386/llrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/llrintl.lo: $(srcdir)/src/math/x86_64/llrintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llround.lo: $(srcdir)/src/math/llround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llround.lo: $(srcdir)/src/math/aarch64/llround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llroundf.lo: $(srcdir)/src/math/llroundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/llroundf.lo: $(srcdir)/src/math/aarch64/llroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/llroundl.lo: $(srcdir)/src/math/llroundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log.lo: $(srcdir)/src/math/log.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10.lo: $(srcdir)/src/math/log10.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10f.lo: $(srcdir)/src/math/log10f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log10l.lo: $(srcdir)/src/math/log10l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1p.lo: $(srcdir)/src/math/log1p.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1pf.lo: $(srcdir)/src/math/log1pf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log1pl.lo: $(srcdir)/src/math/log1pl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2.lo: $(srcdir)/src/math/log2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2_data.lo: $(srcdir)/src/math/log2_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2f.lo: $(srcdir)/src/math/log2f.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2f_data.lo: $(srcdir)/src/math/log2f_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log2l.lo: $(srcdir)/src/math/log2l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/log_data.lo: $(srcdir)/src/math/log_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logb.lo: $(srcdir)/src/math/logb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logbf.lo: $(srcdir)/src/math/logbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logbl.lo: $(srcdir)/src/math/logbl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logf.lo: $(srcdir)/src/math/logf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logf_data.lo: $(srcdir)/src/math/logf_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/logl.lo: $(srcdir)/src/math/logl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrint.lo: $(srcdir)/src/math/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lrint.lo: $(srcdir)/src/math/aarch64/lrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrint.lo: $(srcdir)/src/math/i386/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lrint.lo: $(srcdir)/src/math/powerpc64/lrint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrint.lo: $(srcdir)/src/math/x86_64/lrint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrintf.lo: $(srcdir)/src/math/lrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lrintf.lo: $(srcdir)/src/math/aarch64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrintf.lo: $(srcdir)/src/math/i386/lrintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lrintf.lo: $(srcdir)/src/math/powerpc64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrintf.lo: $(srcdir)/src/math/x86_64/lrintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lrintl.lo: $(srcdir)/src/math/lrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/lrintl.lo: $(srcdir)/src/math/i386/lrintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/lrintl.lo: $(srcdir)/src/math/x86_64/lrintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lround.lo: $(srcdir)/src/math/lround.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lround.lo: $(srcdir)/src/math/aarch64/lround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lround.lo: $(srcdir)/src/math/powerpc64/lround.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lroundf.lo: $(srcdir)/src/math/lroundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/lroundf.lo: $(srcdir)/src/math/aarch64/lroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/lroundf.lo: $(srcdir)/src/math/powerpc64/lroundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/lroundl.lo: $(srcdir)/src/math/lroundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modf.lo: $(srcdir)/src/math/modf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modff.lo: $(srcdir)/src/math/modff.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/modfl.lo: $(srcdir)/src/math/modfl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nan.lo: $(srcdir)/src/math/nan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nanf.lo: $(srcdir)/src/math/nanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nanl.lo: $(srcdir)/src/math/nanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyint.lo: $(srcdir)/src/math/nearbyint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/nearbyint.lo: $(srcdir)/src/math/aarch64/nearbyint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyint.lo: $(srcdir)/src/math/s390x/nearbyint.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyintf.lo: $(srcdir)/src/math/nearbyintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/nearbyintf.lo: $(srcdir)/src/math/aarch64/nearbyintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyintf.lo: $(srcdir)/src/math/s390x/nearbyintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nearbyintl.lo: $(srcdir)/src/math/nearbyintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/nearbyintl.lo: $(srcdir)/src/math/s390x/nearbyintl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafter.lo: $(srcdir)/src/math/nextafter.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafterf.lo: $(srcdir)/src/math/nextafterf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nextafterl.lo: $(srcdir)/src/math/nextafterl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttoward.lo: $(srcdir)/src/math/nexttoward.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttowardf.lo: $(srcdir)/src/math/nexttowardf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/nexttowardl.lo: $(srcdir)/src/math/nexttowardl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/pow.lo: $(srcdir)/src/math/pow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/pow_data.lo: $(srcdir)/src/math/pow_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powf.lo: $(srcdir)/src/math/powf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powf_data.lo: $(srcdir)/src/math/powf_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powl.lo: $(srcdir)/src/math/powl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainder.lo: $(srcdir)/src/math/remainder.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainder.lo: $(srcdir)/src/math/i386/remainder.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainderf.lo: $(srcdir)/src/math/remainderf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainderf.lo: $(srcdir)/src/math/i386/remainderf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remainderl.lo: $(srcdir)/src/math/remainderl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/remainderl.lo: $(srcdir)/src/math/i386/remainderl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/remainderl.lo: $(srcdir)/src/math/x86_64/remainderl.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquo.lo: $(srcdir)/src/math/remquo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquof.lo: $(srcdir)/src/math/remquof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/remquol.lo: $(srcdir)/src/math/remquol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/remquol.lo: $(srcdir)/src/math/x86_64/remquol.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rint.lo: $(srcdir)/src/math/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/rint.lo: $(srcdir)/src/math/aarch64/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rint.lo: $(srcdir)/src/math/i386/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rint.lo: $(srcdir)/src/math/s390x/rint.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rintf.lo: $(srcdir)/src/math/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/rintf.lo: $(srcdir)/src/math/aarch64/rintf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rintf.lo: $(srcdir)/src/math/i386/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rintf.lo: $(srcdir)/src/math/s390x/rintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/rintl.lo: $(srcdir)/src/math/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/rintl.lo: $(srcdir)/src/math/i386/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/rintl.lo: $(srcdir)/src/math/s390x/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/rintl.lo: $(srcdir)/src/math/x86_64/rintl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/round.lo: $(srcdir)/src/math/round.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/round.lo: $(srcdir)/src/math/aarch64/round.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/round.lo: $(srcdir)/src/math/powerpc64/round.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/round.lo: $(srcdir)/src/math/s390x/round.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/roundf.lo: $(srcdir)/src/math/roundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/roundf.lo: $(srcdir)/src/math/aarch64/roundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/roundf.lo: $(srcdir)/src/math/powerpc64/roundf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/roundf.lo: $(srcdir)/src/math/s390x/roundf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/roundl.lo: $(srcdir)/src/math/roundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/roundl.lo: $(srcdir)/src/math/s390x/roundl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalb.lo: $(srcdir)/src/math/scalb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbf.lo: $(srcdir)/src/math/scalbf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbln.lo: $(srcdir)/src/math/scalbln.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalblnf.lo: $(srcdir)/src/math/scalblnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalblnl.lo: $(srcdir)/src/math/scalblnl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbn.lo: $(srcdir)/src/math/scalbn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbnf.lo: $(srcdir)/src/math/scalbnf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/scalbnl.lo: $(srcdir)/src/math/scalbnl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/signgam.lo: $(srcdir)/src/math/signgam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/significand.lo: $(srcdir)/src/math/significand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/significandf.lo: $(srcdir)/src/math/significandf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sin.lo: $(srcdir)/src/math/sin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincos.lo: $(srcdir)/src/math/sincos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincosf.lo: $(srcdir)/src/math/sincosf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sincosl.lo: $(srcdir)/src/math/sincosl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinf.lo: $(srcdir)/src/math/sinf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinh.lo: $(srcdir)/src/math/sinh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinhf.lo: $(srcdir)/src/math/sinhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinhl.lo: $(srcdir)/src/math/sinhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sinl.lo: $(srcdir)/src/math/sinl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrt.lo: $(srcdir)/src/math/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/sqrt.lo: $(srcdir)/src/math/aarch64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/sqrt.lo: $(srcdir)/src/math/arm/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrt.lo: $(srcdir)/src/math/i386/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/sqrt.lo: $(srcdir)/src/math/mips/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/sqrt.lo: $(srcdir)/src/math/powerpc/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/sqrt.lo: $(srcdir)/src/math/powerpc64/sqrt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/sqrt.lo: $(srcdir)/src/math/riscv32/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/sqrt.lo: $(srcdir)/src/math/riscv64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrt.lo: $(srcdir)/src/math/s390x/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrt.lo: $(srcdir)/src/math/x86_64/sqrt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrt_data.lo: $(srcdir)/src/math/sqrt_data.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrtf.lo: $(srcdir)/src/math/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/sqrtf.lo: $(srcdir)/src/math/aarch64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/arm/sqrtf.lo: $(srcdir)/src/math/arm/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrtf.lo: $(srcdir)/src/math/i386/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/mips/sqrtf.lo: $(srcdir)/src/math/mips/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc/sqrtf.lo: $(srcdir)/src/math/powerpc/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/sqrtf.lo: $(srcdir)/src/math/powerpc64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv32/sqrtf.lo: $(srcdir)/src/math/riscv32/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/riscv64/sqrtf.lo: $(srcdir)/src/math/riscv64/sqrtf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrtf.lo: $(srcdir)/src/math/s390x/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrtf.lo: $(srcdir)/src/math/x86_64/sqrtf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/sqrtl.lo: $(srcdir)/src/math/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/i386/sqrtl.lo: $(srcdir)/src/math/i386/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/m68k/sqrtl.lo: $(srcdir)/src/math/m68k/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/sqrtl.lo: $(srcdir)/src/math/s390x/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/x86_64/sqrtl.lo: $(srcdir)/src/math/x86_64/sqrtl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tan.lo: $(srcdir)/src/math/tan.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanf.lo: $(srcdir)/src/math/tanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanh.lo: $(srcdir)/src/math/tanh.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanhf.lo: $(srcdir)/src/math/tanhf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanhl.lo: $(srcdir)/src/math/tanhl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tanl.lo: $(srcdir)/src/math/tanl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgamma.lo: $(srcdir)/src/math/tgamma.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgammaf.lo: $(srcdir)/src/math/tgammaf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/tgammal.lo: $(srcdir)/src/math/tgammal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/trunc.lo: $(srcdir)/src/math/trunc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/trunc.lo: $(srcdir)/src/math/aarch64/trunc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/trunc.lo: $(srcdir)/src/math/powerpc64/trunc.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/trunc.lo: $(srcdir)/src/math/s390x/trunc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/truncf.lo: $(srcdir)/src/math/truncf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/aarch64/truncf.lo: $(srcdir)/src/math/aarch64/truncf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/powerpc64/truncf.lo: $(srcdir)/src/math/powerpc64/truncf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/truncf.lo: $(srcdir)/src/math/s390x/truncf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/truncl.lo: $(srcdir)/src/math/truncl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/math/s390x/truncl.lo: $(srcdir)/src/math/s390x/truncl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/a64l.lo: $(srcdir)/src/misc/a64l.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/basename.lo: $(srcdir)/src/misc/basename.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/dirname.lo: $(srcdir)/src/misc/dirname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffs.lo: $(srcdir)/src/misc/ffs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffsl.lo: $(srcdir)/src/misc/ffsl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ffsll.lo: $(srcdir)/src/misc/ffsll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/fmtmsg.lo: $(srcdir)/src/misc/fmtmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/forkpty.lo: $(srcdir)/src/misc/forkpty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/get_current_dir_name.lo: \
  $(srcdir)/src/misc/get_current_dir_name.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getauxval.lo: $(srcdir)/src/misc/getauxval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getdomainname.lo: $(srcdir)/src/misc/getdomainname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getentropy.lo: $(srcdir)/src/misc/getentropy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/gethostid.lo: $(srcdir)/src/misc/gethostid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getopt.lo: $(srcdir)/src/misc/getopt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getopt_long.lo: $(srcdir)/src/misc/getopt_long.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getpriority.lo: $(srcdir)/src/misc/getpriority.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getresgid.lo: $(srcdir)/src/misc/getresgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getresuid.lo: $(srcdir)/src/misc/getresuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getrlimit.lo: $(srcdir)/src/misc/getrlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getrusage.lo: $(srcdir)/src/misc/getrusage.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/getsubopt.lo: $(srcdir)/src/misc/getsubopt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/initgroups.lo: $(srcdir)/src/misc/initgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ioctl.lo: $(srcdir)/src/misc/ioctl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/issetugid.lo: $(srcdir)/src/misc/issetugid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/lockf.lo: $(srcdir)/src/misc/lockf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/login_tty.lo: $(srcdir)/src/misc/login_tty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/mntent.lo: $(srcdir)/src/misc/mntent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/nftw.lo: $(srcdir)/src/misc/nftw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/ptsname.lo: $(srcdir)/src/misc/ptsname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setpriority.lo: $(srcdir)/src/misc/setpriority.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/syscall.lo: $(srcdir)/src/misc/syscall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/syslog.lo: $(srcdir)/src/misc/syslog.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/openpty.lo: $(srcdir)/src/misc/openpty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/pty.lo: $(srcdir)/src/misc/pty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/realpath.lo: $(srcdir)/src/misc/realpath.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setdomainname.lo: $(srcdir)/src/misc/setdomainname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/setrlimit.lo: $(srcdir)/src/misc/setrlimit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/uname.lo: $(srcdir)/src/misc/uname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/misc/wordexp.lo: $(srcdir)/src/misc/wordexp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/madvise.lo: $(srcdir)/src/mman/madvise.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mincore.lo: $(srcdir)/src/mman/mincore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mlock.lo: $(srcdir)/src/mman/mlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mlockall.lo: $(srcdir)/src/mman/mlockall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mmap.lo: $(srcdir)/src/mman/mmap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mprotect.lo: $(srcdir)/src/mman/mprotect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/mremap.lo: $(srcdir)/src/mman/mremap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/msync.lo: $(srcdir)/src/mman/msync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munlock.lo: $(srcdir)/src/mman/munlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munlockall.lo: $(srcdir)/src/mman/munlockall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/munmap.lo: $(srcdir)/src/mman/munmap.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/posix_madvise.lo: $(srcdir)/src/mman/posix_madvise.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mman/shm_open.lo: $(srcdir)/src/mman/shm_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_close.lo: $(srcdir)/src/mq/mq_close.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_getattr.lo: $(srcdir)/src/mq/mq_getattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_notify.lo: $(srcdir)/src/mq/mq_notify.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_open.lo: $(srcdir)/src/mq/mq_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/x32/mq_open.lo: $(srcdir)/src/mq/x32/mq_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_receive.lo: $(srcdir)/src/mq/mq_receive.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_send.lo: $(srcdir)/src/mq/mq_send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_setattr.lo: $(srcdir)/src/mq/mq_setattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/x32/mq_setattr.lo: $(srcdir)/src/mq/x32/mq_setattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_timedreceive.lo: $(srcdir)/src/mq/mq_timedreceive.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_timedsend.lo: $(srcdir)/src/mq/mq_timedsend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/mq/mq_unlink.lo: $(srcdir)/src/mq/mq_unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/btowc.lo: $(srcdir)/src/multibyte/btowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/c16rtomb.lo: $(srcdir)/src/multibyte/c16rtomb.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/c32rtomb.lo: $(srcdir)/src/multibyte/c32rtomb.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/internal.lo: $(srcdir)/src/multibyte/internal.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mblen.lo: $(srcdir)/src/multibyte/mblen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrlen.lo: $(srcdir)/src/multibyte/mbrlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtoc16.lo: $(srcdir)/src/multibyte/mbrtoc16.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtoc32.lo: $(srcdir)/src/multibyte/mbrtoc32.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbrtowc.lo: $(srcdir)/src/multibyte/mbrtowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsinit.lo: $(srcdir)/src/multibyte/mbsinit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsnrtowcs.lo: $(srcdir)/src/multibyte/mbsnrtowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbsrtowcs.lo: $(srcdir)/src/multibyte/mbsrtowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbstowcs.lo: $(srcdir)/src/multibyte/mbstowcs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/mbtowc.lo: $(srcdir)/src/multibyte/mbtowc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcrtomb.lo: $(srcdir)/src/multibyte/wcrtomb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcsnrtombs.lo: $(srcdir)/src/multibyte/wcsnrtombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcsrtombs.lo: $(srcdir)/src/multibyte/wcsrtombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wcstombs.lo: $(srcdir)/src/multibyte/wcstombs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wctob.lo: $(srcdir)/src/multibyte/wctob.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/multibyte/wctomb.lo: $(srcdir)/src/multibyte/wctomb.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/accept.lo: $(srcdir)/src/network/accept.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/accept4.lo: $(srcdir)/src/network/accept4.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/bind.lo: $(srcdir)/src/network/bind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/connect.lo: $(srcdir)/src/network/connect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_comp.lo: $(srcdir)/src/network/dn_comp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_expand.lo: $(srcdir)/src/network/dn_expand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dn_skipname.lo: $(srcdir)/src/network/dn_skipname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/dns_parse.lo: $(srcdir)/src/network/dns_parse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ent.lo: $(srcdir)/src/network/ent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ether.lo: $(srcdir)/src/network/ether.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/freeaddrinfo.lo: $(srcdir)/src/network/freeaddrinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gai_strerror.lo: $(srcdir)/src/network/gai_strerror.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getaddrinfo.lo: $(srcdir)/src/network/getaddrinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyaddr.lo: $(srcdir)/src/network/gethostbyaddr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyaddr_r.lo: $(srcdir)/src/network/gethostbyaddr_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname.lo: $(srcdir)/src/network/gethostbyname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname2.lo: $(srcdir)/src/network/gethostbyname2.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname2_r.lo: $(srcdir)/src/network/gethostbyname2_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/gethostbyname_r.lo: $(srcdir)/src/network/gethostbyname_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getifaddrs.lo: $(srcdir)/src/network/getifaddrs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getnameinfo.lo: $(srcdir)/src/network/getnameinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getpeername.lo: $(srcdir)/src/network/getpeername.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyname.lo: $(srcdir)/src/network/getservbyname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyname_r.lo: $(srcdir)/src/network/getservbyname_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyport.lo: $(srcdir)/src/network/getservbyport.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getservbyport_r.lo: $(srcdir)/src/network/getservbyport_r.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getsockname.lo: $(srcdir)/src/network/getsockname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/getsockopt.lo: $(srcdir)/src/network/getsockopt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/h_errno.lo: $(srcdir)/src/network/h_errno.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/herror.lo: $(srcdir)/src/network/herror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/hstrerror.lo: $(srcdir)/src/network/hstrerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/htonl.lo: $(srcdir)/src/network/htonl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/htons.lo: $(srcdir)/src/network/htons.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_freenameindex.lo: $(srcdir)/src/network/if_freenameindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_indextoname.lo: $(srcdir)/src/network/if_indextoname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_nameindex.lo: $(srcdir)/src/network/if_nameindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/if_nametoindex.lo: $(srcdir)/src/network/if_nametoindex.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/in6addr_any.lo: $(srcdir)/src/network/in6addr_any.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/in6addr_loopback.lo: $(srcdir)/src/network/in6addr_loopback.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_addr.lo: $(srcdir)/src/network/inet_addr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_aton.lo: $(srcdir)/src/network/inet_aton.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_legacy.lo: $(srcdir)/src/network/inet_legacy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_ntoa.lo: $(srcdir)/src/network/inet_ntoa.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_ntop.lo: $(srcdir)/src/network/inet_ntop.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/inet_pton.lo: $(srcdir)/src/network/inet_pton.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/listen.lo: $(srcdir)/src/network/listen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_ipliteral.lo: $(srcdir)/src/network/lookup_ipliteral.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_name.lo: $(srcdir)/src/network/lookup_name.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/lookup_serv.lo: $(srcdir)/src/network/lookup_serv.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/netlink.lo: $(srcdir)/src/network/netlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/netname.lo: $(srcdir)/src/network/netname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ns_parse.lo: $(srcdir)/src/network/ns_parse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ntohl.lo: $(srcdir)/src/network/ntohl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/ntohs.lo: $(srcdir)/src/network/ntohs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/proto.lo: $(srcdir)/src/network/proto.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recv.lo: $(srcdir)/src/network/recv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvmmsg.lo: $(srcdir)/src/network/recvmmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_init.lo: $(srcdir)/src/network/res_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_mkquery.lo: $(srcdir)/src/network/res_mkquery.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_msend.lo: $(srcdir)/src/network/res_msend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_query.lo: $(srcdir)/src/network/res_query.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_querydomain.lo: $(srcdir)/src/network/res_querydomain.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_send.lo: $(srcdir)/src/network/res_send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/res_state.lo: $(srcdir)/src/network/res_state.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/resolvconf.lo: $(srcdir)/src/network/resolvconf.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvfrom.lo: $(srcdir)/src/network/recvfrom.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/recvmsg.lo: $(srcdir)/src/network/recvmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/send.lo: $(srcdir)/src/network/send.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendmmsg.lo: $(srcdir)/src/network/sendmmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendmsg.lo: $(srcdir)/src/network/sendmsg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sendto.lo: $(srcdir)/src/network/sendto.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/serv.lo: $(srcdir)/src/network/serv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/setsockopt.lo: $(srcdir)/src/network/setsockopt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/shutdown.lo: $(srcdir)/src/network/shutdown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/sockatmark.lo: $(srcdir)/src/network/sockatmark.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/socket.lo: $(srcdir)/src/network/socket.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/network/socketpair.lo: $(srcdir)/src/network/socketpair.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetgrent.lo: $(srcdir)/src/passwd/fgetgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetpwent.lo: $(srcdir)/src/passwd/fgetpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/fgetspent.lo: $(srcdir)/src/passwd/fgetspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgr_a.lo: $(srcdir)/src/passwd/getgr_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgr_r.lo: $(srcdir)/src/passwd/getgr_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrent.lo: $(srcdir)/src/passwd/getgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrent_a.lo: $(srcdir)/src/passwd/getgrent_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getgrouplist.lo: $(srcdir)/src/passwd/getgrouplist.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpw_a.lo: $(srcdir)/src/passwd/getpw_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpw_r.lo: $(srcdir)/src/passwd/getpw_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpwent.lo: $(srcdir)/src/passwd/getpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getpwent_a.lo: $(srcdir)/src/passwd/getpwent_a.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspent.lo: $(srcdir)/src/passwd/getspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspnam.lo: $(srcdir)/src/passwd/getspnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/getspnam_r.lo: $(srcdir)/src/passwd/getspnam_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/lckpwdf.lo: $(srcdir)/src/passwd/lckpwdf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/nscd_query.lo: $(srcdir)/src/passwd/nscd_query.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putgrent.lo: $(srcdir)/src/passwd/putgrent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putpwent.lo: $(srcdir)/src/passwd/putpwent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/passwd/putspent.lo: $(srcdir)/src/passwd/putspent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/__rand48_step.lo: $(srcdir)/src/prng/__rand48_step.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/__seed48.lo: $(srcdir)/src/prng/__seed48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/drand48.lo: $(srcdir)/src/prng/drand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/lcong48.lo: $(srcdir)/src/prng/lcong48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/lrand48.lo: $(srcdir)/src/prng/lrand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/mrand48.lo: $(srcdir)/src/prng/mrand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/rand.lo: $(srcdir)/src/prng/rand.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/rand_r.lo: $(srcdir)/src/prng/rand_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/random.lo: $(srcdir)/src/prng/random.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/seed48.lo: $(srcdir)/src/prng/seed48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/prng/srand48.lo: $(srcdir)/src/prng/srand48.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/_Fork.lo: $(srcdir)/src/process/_Fork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execl.lo: $(srcdir)/src/process/execl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execle.lo: $(srcdir)/src/process/execle.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execlp.lo: $(srcdir)/src/process/execlp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execv.lo: $(srcdir)/src/process/execv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execve.lo: $(srcdir)/src/process/execve.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/execvp.lo: $(srcdir)/src/process/execvp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/fexecve.lo: $(srcdir)/src/process/fexecve.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/fork.lo: $(srcdir)/src/process/fork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn.lo: $(srcdir)/src/process/posix_spawn.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addchdir.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_addchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addclose.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_addclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_adddup2.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_adddup2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addfchdir.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_addfchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_addopen.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_addopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_destroy.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawn_file_actions_init.lo: \
  $(srcdir)/src/process/posix_spawn_file_actions_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_destroy.lo: \
  $(srcdir)/src/process/posix_spawnattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getflags.lo: \
  $(srcdir)/src/process/posix_spawnattr_getflags.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getpgroup.lo: \
  $(srcdir)/src/process/posix_spawnattr_getpgroup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getsigdefault.lo: \
  $(srcdir)/src/process/posix_spawnattr_getsigdefault.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_getsigmask.lo: \
  $(srcdir)/src/process/posix_spawnattr_getsigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_init.lo: \
  $(srcdir)/src/process/posix_spawnattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_sched.lo: \
  $(srcdir)/src/process/posix_spawnattr_sched.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setflags.lo: \
  $(srcdir)/src/process/posix_spawnattr_setflags.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setpgroup.lo: \
  $(srcdir)/src/process/posix_spawnattr_setpgroup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setsigdefault.lo: \
  $(srcdir)/src/process/posix_spawnattr_setsigdefault.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnattr_setsigmask.lo: \
  $(srcdir)/src/process/posix_spawnattr_setsigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/posix_spawnp.lo: $(srcdir)/src/process/posix_spawnp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/system.lo: $(srcdir)/src/process/system.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/vfork.lo: $(srcdir)/src/process/vfork.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/wait.lo: $(srcdir)/src/process/wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/waitid.lo: $(srcdir)/src/process/waitid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/process/waitpid.lo: $(srcdir)/src/process/waitpid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/fnmatch.lo: $(srcdir)/src/regex/fnmatch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/glob.lo: $(srcdir)/src/regex/glob.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regcomp.lo: $(srcdir)/src/regex/regcomp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regerror.lo: $(srcdir)/src/regex/regerror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/regexec.lo: $(srcdir)/src/regex/regexec.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/regex/tre-mem.lo: $(srcdir)/src/regex/tre-mem.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/affinity.lo: $(srcdir)/src/sched/affinity.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_cpucount.lo: $(srcdir)/src/sched/sched_cpucount.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getcpu.lo: $(srcdir)/src/sched/sched_getcpu.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getparam.lo: $(srcdir)/src/sched/sched_getparam.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_getscheduler.lo: $(srcdir)/src/sched/sched_getscheduler.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_rr_get_interval.lo: \
  $(srcdir)/src/sched/sched_rr_get_interval.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_setparam.lo: $(srcdir)/src/sched/sched_setparam.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_setscheduler.lo: $(srcdir)/src/sched/sched_setscheduler.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_yield.lo: $(srcdir)/src/sched/sched_yield.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/sched/sched_get_priority_max.lo: \
  $(srcdir)/src/sched/sched_get_priority_max.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/hsearch.lo: $(srcdir)/src/search/hsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/insque.lo: $(srcdir)/src/search/insque.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/lsearch.lo: $(srcdir)/src/search/lsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tdelete.lo: $(srcdir)/src/search/tdelete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tdestroy.lo: $(srcdir)/src/search/tdestroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tfind.lo: $(srcdir)/src/search/tfind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/tsearch.lo: $(srcdir)/src/search/tsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/search/twalk.lo: $(srcdir)/src/search/twalk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/poll.lo: $(srcdir)/src/select/poll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/ppoll.lo: $(srcdir)/src/select/ppoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/pselect.lo: $(srcdir)/src/select/pselect.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/select/select.lo: $(srcdir)/src/select/select.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/longjmp.lo: $(srcdir)/src/setjmp/longjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/setjmp/setjmp.lo: $(srcdir)/src/setjmp/setjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/block.lo: $(srcdir)/src/signal/block.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/getitimer.lo: $(srcdir)/src/signal/getitimer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/x32/getitimer.lo: $(srcdir)/src/signal/x32/getitimer.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/kill.lo: $(srcdir)/src/signal/kill.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/killpg.lo: $(srcdir)/src/signal/killpg.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/psiginfo.lo: $(srcdir)/src/signal/psiginfo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/psignal.lo: $(srcdir)/src/signal/psignal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/raise.lo: $(srcdir)/src/signal/raise.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/restore.lo: $(srcdir)/src/signal/restore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/setitimer.lo: $(srcdir)/src/signal/setitimer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/x32/setitimer.lo: $(srcdir)/src/signal/x32/setitimer.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaction.lo: $(srcdir)/src/signal/sigaction.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaddset.lo: $(srcdir)/src/signal/sigaddset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigaltstack.lo: $(srcdir)/src/signal/sigaltstack.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigandset.lo: $(srcdir)/src/signal/sigandset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigdelset.lo: $(srcdir)/src/signal/sigdelset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigemptyset.lo: $(srcdir)/src/signal/sigemptyset.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigfillset.lo: $(srcdir)/src/signal/sigfillset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sighold.lo: $(srcdir)/src/signal/sighold.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigignore.lo: $(srcdir)/src/signal/sigignore.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/siginterrupt.lo: $(srcdir)/src/signal/siginterrupt.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigisemptyset.lo: $(srcdir)/src/signal/sigisemptyset.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigismember.lo: $(srcdir)/src/signal/sigismember.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/siglongjmp.lo: $(srcdir)/src/signal/siglongjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/signal.lo: $(srcdir)/src/signal/signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigorset.lo: $(srcdir)/src/signal/sigorset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigpause.lo: $(srcdir)/src/signal/sigpause.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigpending.lo: $(srcdir)/src/signal/sigpending.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigprocmask.lo: $(srcdir)/src/signal/sigprocmask.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigqueue.lo: $(srcdir)/src/signal/sigqueue.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrelse.lo: $(srcdir)/src/signal/sigrelse.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrtmax.lo: $(srcdir)/src/signal/sigrtmax.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigrtmin.lo: $(srcdir)/src/signal/sigrtmin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigset.lo: $(srcdir)/src/signal/sigset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsetjmp.lo: $(srcdir)/src/signal/sigsetjmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsetjmp_tail.lo: $(srcdir)/src/signal/sigsetjmp_tail.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigsuspend.lo: $(srcdir)/src/signal/sigsuspend.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigtimedwait.lo: $(srcdir)/src/signal/sigtimedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigwait.lo: $(srcdir)/src/signal/sigwait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/signal/sigwaitinfo.lo: $(srcdir)/src/signal/sigwaitinfo.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/__xstat.lo: $(srcdir)/src/stat/__xstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/chmod.lo: $(srcdir)/src/stat/chmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fchmod.lo: $(srcdir)/src/stat/fchmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fchmodat.lo: $(srcdir)/src/stat/fchmodat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fstat.lo: $(srcdir)/src/stat/fstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/fstatat.lo: $(srcdir)/src/stat/fstatat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/futimens.lo: $(srcdir)/src/stat/futimens.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/futimesat.lo: $(srcdir)/src/stat/futimesat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/lchmod.lo: $(srcdir)/src/stat/lchmod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/lstat.lo: $(srcdir)/src/stat/lstat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkdir.lo: $(srcdir)/src/stat/mkdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkdirat.lo: $(srcdir)/src/stat/mkdirat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkfifo.lo: $(srcdir)/src/stat/mkfifo.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mkfifoat.lo: $(srcdir)/src/stat/mkfifoat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mknod.lo: $(srcdir)/src/stat/mknod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/mknodat.lo: $(srcdir)/src/stat/mknodat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/stat.lo: $(srcdir)/src/stat/stat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/statvfs.lo: $(srcdir)/src/stat/statvfs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/umask.lo: $(srcdir)/src/stat/umask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stat/utimensat.lo: $(srcdir)/src/stat/utimensat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fclose_ca.lo: $(srcdir)/src/stdio/__fclose_ca.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fdopen.lo: $(srcdir)/src/stdio/__fdopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fmodeflags.lo: $(srcdir)/src/stdio/__fmodeflags.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__fopen_rb_ca.lo: $(srcdir)/src/stdio/__fopen_rb_ca.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__lockfile.lo: $(srcdir)/src/stdio/__lockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__overflow.lo: $(srcdir)/src/stdio/__overflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_close.lo: $(srcdir)/src/stdio/__stdio_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_exit.lo: $(srcdir)/src/stdio/__stdio_exit.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_read.lo: $(srcdir)/src/stdio/__stdio_read.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_seek.lo: $(srcdir)/src/stdio/__stdio_seek.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdio_write.lo: $(srcdir)/src/stdio/__stdio_write.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__stdout_write.lo: $(srcdir)/src/stdio/__stdout_write.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__toread.lo: $(srcdir)/src/stdio/__toread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__towrite.lo: $(srcdir)/src/stdio/__towrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/__uflow.lo: $(srcdir)/src/stdio/__uflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/asprintf.lo: $(srcdir)/src/stdio/asprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/clearerr.lo: $(srcdir)/src/stdio/clearerr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/dprintf.lo: $(srcdir)/src/stdio/dprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ext.lo: $(srcdir)/src/stdio/ext.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ext2.lo: $(srcdir)/src/stdio/ext2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fclose.lo: $(srcdir)/src/stdio/fclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/feof.lo: $(srcdir)/src/stdio/feof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ferror.lo: $(srcdir)/src/stdio/ferror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fflush.lo: $(srcdir)/src/stdio/fflush.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetc.lo: $(srcdir)/src/stdio/fgetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetln.lo: $(srcdir)/src/stdio/fgetln.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetpos.lo: $(srcdir)/src/stdio/fgetpos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgets.lo: $(srcdir)/src/stdio/fgets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetwc.lo: $(srcdir)/src/stdio/fgetwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fgetws.lo: $(srcdir)/src/stdio/fgetws.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fileno.lo: $(srcdir)/src/stdio/fileno.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/flockfile.lo: $(srcdir)/src/stdio/flockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fmemopen.lo: $(srcdir)/src/stdio/fmemopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fopen.lo: $(srcdir)/src/stdio/fopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fopencookie.lo: $(srcdir)/src/stdio/fopencookie.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fprintf.lo: $(srcdir)/src/stdio/fprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputc.lo: $(srcdir)/src/stdio/fputc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputs.lo: $(srcdir)/src/stdio/fputs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputwc.lo: $(srcdir)/src/stdio/fputwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fputws.lo: $(srcdir)/src/stdio/fputws.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fread.lo: $(srcdir)/src/stdio/fread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/freopen.lo: $(srcdir)/src/stdio/freopen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fscanf.lo: $(srcdir)/src/stdio/fscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fseek.lo: $(srcdir)/src/stdio/fseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fsetpos.lo: $(srcdir)/src/stdio/fsetpos.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ftell.lo: $(srcdir)/src/stdio/ftell.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ftrylockfile.lo: $(srcdir)/src/stdio/ftrylockfile.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/funlockfile.lo: $(srcdir)/src/stdio/funlockfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwide.lo: $(srcdir)/src/stdio/fwide.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwprintf.lo: $(srcdir)/src/stdio/fwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwrite.lo: $(srcdir)/src/stdio/fwrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/fwscanf.lo: $(srcdir)/src/stdio/fwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getc.lo: $(srcdir)/src/stdio/getc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getc_unlocked.lo: $(srcdir)/src/stdio/getc_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getchar.lo: $(srcdir)/src/stdio/getchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getchar_unlocked.lo: $(srcdir)/src/stdio/getchar_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getdelim.lo: $(srcdir)/src/stdio/getdelim.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getline.lo: $(srcdir)/src/stdio/getline.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/gets.lo: $(srcdir)/src/stdio/gets.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getw.lo: $(srcdir)/src/stdio/getw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getwc.lo: $(srcdir)/src/stdio/getwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/getwchar.lo: $(srcdir)/src/stdio/getwchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ofl.lo: $(srcdir)/src/stdio/ofl.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ofl_add.lo: $(srcdir)/src/stdio/ofl_add.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/open_memstream.lo: $(srcdir)/src/stdio/open_memstream.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/open_wmemstream.lo: $(srcdir)/src/stdio/open_wmemstream.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/pclose.lo: $(srcdir)/src/stdio/pclose.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/perror.lo: $(srcdir)/src/stdio/perror.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/popen.lo: $(srcdir)/src/stdio/popen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/printf.lo: $(srcdir)/src/stdio/printf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putc.lo: $(srcdir)/src/stdio/putc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putc_unlocked.lo: $(srcdir)/src/stdio/putc_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putchar.lo: $(srcdir)/src/stdio/putchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putchar_unlocked.lo: $(srcdir)/src/stdio/putchar_unlocked.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/puts.lo: $(srcdir)/src/stdio/puts.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putw.lo: $(srcdir)/src/stdio/putw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putwc.lo: $(srcdir)/src/stdio/putwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/putwchar.lo: $(srcdir)/src/stdio/putwchar.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/remove.lo: $(srcdir)/src/stdio/remove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/rename.lo: $(srcdir)/src/stdio/rename.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/rewind.lo: $(srcdir)/src/stdio/rewind.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/scanf.lo: $(srcdir)/src/stdio/scanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setbuf.lo: $(srcdir)/src/stdio/setbuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setbuffer.lo: $(srcdir)/src/stdio/setbuffer.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setlinebuf.lo: $(srcdir)/src/stdio/setlinebuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/setvbuf.lo: $(srcdir)/src/stdio/setvbuf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/snprintf.lo: $(srcdir)/src/stdio/snprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/sprintf.lo: $(srcdir)/src/stdio/sprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/sscanf.lo: $(srcdir)/src/stdio/sscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stderr.lo: $(srcdir)/src/stdio/stderr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stdin.lo: $(srcdir)/src/stdio/stdin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/stdout.lo: $(srcdir)/src/stdio/stdout.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/swprintf.lo: $(srcdir)/src/stdio/swprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/swscanf.lo: $(srcdir)/src/stdio/swscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tempnam.lo: $(srcdir)/src/stdio/tempnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tmpfile.lo: $(srcdir)/src/stdio/tmpfile.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/tmpnam.lo: $(srcdir)/src/stdio/tmpnam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ungetc.lo: $(srcdir)/src/stdio/ungetc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/ungetwc.lo: $(srcdir)/src/stdio/ungetwc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vasprintf.lo: $(srcdir)/src/stdio/vasprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vdprintf.lo: $(srcdir)/src/stdio/vdprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfprintf.lo: $(srcdir)/src/stdio/vfprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfscanf.lo: $(srcdir)/src/stdio/vfscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfwprintf.lo: $(srcdir)/src/stdio/vfwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vfwscanf.lo: $(srcdir)/src/stdio/vfwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vprintf.lo: $(srcdir)/src/stdio/vprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vscanf.lo: $(srcdir)/src/stdio/vscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsnprintf.lo: $(srcdir)/src/stdio/vsnprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsprintf.lo: $(srcdir)/src/stdio/vsprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vsscanf.lo: $(srcdir)/src/stdio/vsscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vswprintf.lo: $(srcdir)/src/stdio/vswprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vswscanf.lo: $(srcdir)/src/stdio/vswscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vwprintf.lo: $(srcdir)/src/stdio/vwprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/vwscanf.lo: $(srcdir)/src/stdio/vwscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/wprintf.lo: $(srcdir)/src/stdio/wprintf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdio/wscanf.lo: $(srcdir)/src/stdio/wscanf.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/abs.lo: $(srcdir)/src/stdlib/abs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atof.lo: $(srcdir)/src/stdlib/atof.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atoi.lo: $(srcdir)/src/stdlib/atoi.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atol.lo: $(srcdir)/src/stdlib/atol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/atoll.lo: $(srcdir)/src/stdlib/atoll.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/bsearch.lo: $(srcdir)/src/stdlib/bsearch.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/div.lo: $(srcdir)/src/stdlib/div.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/ecvt.lo: $(srcdir)/src/stdlib/ecvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/fcvt.lo: $(srcdir)/src/stdlib/fcvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/gcvt.lo: $(srcdir)/src/stdlib/gcvt.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/imaxabs.lo: $(srcdir)/src/stdlib/imaxabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/imaxdiv.lo: $(srcdir)/src/stdlib/imaxdiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/labs.lo: $(srcdir)/src/stdlib/labs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/ldiv.lo: $(srcdir)/src/stdlib/ldiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/llabs.lo: $(srcdir)/src/stdlib/llabs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/lldiv.lo: $(srcdir)/src/stdlib/lldiv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/qsort.lo: $(srcdir)/src/stdlib/qsort.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/qsort_nr.lo: $(srcdir)/src/stdlib/qsort_nr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/strtod.lo: $(srcdir)/src/stdlib/strtod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/strtol.lo: $(srcdir)/src/stdlib/strtol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/wcstod.lo: $(srcdir)/src/stdlib/wcstod.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/stdlib/wcstol.lo: $(srcdir)/src/stdlib/wcstol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bcmp.lo: $(srcdir)/src/string/bcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bcopy.lo: $(srcdir)/src/string/bcopy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/bzero.lo: $(srcdir)/src/string/bzero.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/explicit_bzero.lo: $(srcdir)/src/string/explicit_bzero.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/index.lo: $(srcdir)/src/string/index.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memccpy.lo: $(srcdir)/src/string/memccpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memchr.lo: $(srcdir)/src/string/memchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memcmp.lo: $(srcdir)/src/string/memcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memcpy.lo: $(srcdir)/src/string/memcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memmem.lo: $(srcdir)/src/string/memmem.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memmove.lo: $(srcdir)/src/string/memmove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/mempcpy.lo: $(srcdir)/src/string/mempcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memrchr.lo: $(srcdir)/src/string/memrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/memset.lo: $(srcdir)/src/string/memset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/rindex.lo: $(srcdir)/src/string/rindex.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/stpcpy.lo: $(srcdir)/src/string/stpcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/stpncpy.lo: $(srcdir)/src/string/stpncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcasecmp.lo: $(srcdir)/src/string/strcasecmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcasestr.lo: $(srcdir)/src/string/strcasestr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcat.lo: $(srcdir)/src/string/strcat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strchr.lo: $(srcdir)/src/string/strchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strchrnul.lo: $(srcdir)/src/string/strchrnul.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcmp.lo: $(srcdir)/src/string/strcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcpy.lo: $(srcdir)/src/string/strcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strcspn.lo: $(srcdir)/src/string/strcspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strdup.lo: $(srcdir)/src/string/strdup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strerror_r.lo: $(srcdir)/src/string/strerror_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlcat.lo: $(srcdir)/src/string/strlcat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlcpy.lo: $(srcdir)/src/string/strlcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strlen.lo: $(srcdir)/src/string/strlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncasecmp.lo: $(srcdir)/src/string/strncasecmp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncat.lo: $(srcdir)/src/string/strncat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncmp.lo: $(srcdir)/src/string/strncmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strncpy.lo: $(srcdir)/src/string/strncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strndup.lo: $(srcdir)/src/string/strndup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strnlen.lo: $(srcdir)/src/string/strnlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strpbrk.lo: $(srcdir)/src/string/strpbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strrchr.lo: $(srcdir)/src/string/strrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strsep.lo: $(srcdir)/src/string/strsep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strsignal.lo: $(srcdir)/src/string/strsignal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strspn.lo: $(srcdir)/src/string/strspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strstr.lo: $(srcdir)/src/string/strstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strtok.lo: $(srcdir)/src/string/strtok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strtok_r.lo: $(srcdir)/src/string/strtok_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/strverscmp.lo: $(srcdir)/src/string/strverscmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/swab.lo: $(srcdir)/src/string/swab.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcpcpy.lo: $(srcdir)/src/string/wcpcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcpncpy.lo: $(srcdir)/src/string/wcpncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscasecmp.lo: $(srcdir)/src/string/wcscasecmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscasecmp_l.lo: $(srcdir)/src/string/wcscasecmp_l.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscat.lo: $(srcdir)/src/string/wcscat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcschr.lo: $(srcdir)/src/string/wcschr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscmp.lo: $(srcdir)/src/string/wcscmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscpy.lo: $(srcdir)/src/string/wcscpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcscspn.lo: $(srcdir)/src/string/wcscspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsdup.lo: $(srcdir)/src/string/wcsdup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcslen.lo: $(srcdir)/src/string/wcslen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncasecmp.lo: $(srcdir)/src/string/wcsncasecmp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncasecmp_l.lo: $(srcdir)/src/string/wcsncasecmp_l.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncat.lo: $(srcdir)/src/string/wcsncat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncmp.lo: $(srcdir)/src/string/wcsncmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsncpy.lo: $(srcdir)/src/string/wcsncpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsnlen.lo: $(srcdir)/src/string/wcsnlen.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcspbrk.lo: $(srcdir)/src/string/wcspbrk.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsrchr.lo: $(srcdir)/src/string/wcsrchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsspn.lo: $(srcdir)/src/string/wcsspn.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcsstr.lo: $(srcdir)/src/string/wcsstr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcstok.lo: $(srcdir)/src/string/wcstok.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wcswcs.lo: $(srcdir)/src/string/wcswcs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemchr.lo: $(srcdir)/src/string/wmemchr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemcmp.lo: $(srcdir)/src/string/wmemcmp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemcpy.lo: $(srcdir)/src/string/wmemcpy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemmove.lo: $(srcdir)/src/string/wmemmove.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/string/wmemset.lo: $(srcdir)/src/string/wmemset.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/__randname.lo: $(srcdir)/src/temp/__randname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkdtemp.lo: $(srcdir)/src/temp/mkdtemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkostemp.lo: $(srcdir)/src/temp/mkostemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkostemps.lo: $(srcdir)/src/temp/mkostemps.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkstemp.lo: $(srcdir)/src/temp/mkstemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mkstemps.lo: $(srcdir)/src/temp/mkstemps.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/temp/mktemp.lo: $(srcdir)/src/temp/mktemp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfgetospeed.lo: $(srcdir)/src/termios/cfgetospeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfmakeraw.lo: $(srcdir)/src/termios/cfmakeraw.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfsetospeed.lo: $(srcdir)/src/termios/cfsetospeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/cfsetspeed.lo: $(srcdir)/src/termios/cfsetspeed.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcdrain.lo: $(srcdir)/src/termios/tcdrain.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcflow.lo: $(srcdir)/src/termios/tcflow.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcflush.lo: $(srcdir)/src/termios/tcflush.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetattr.lo: $(srcdir)/src/termios/tcgetattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetsid.lo: $(srcdir)/src/termios/tcgetsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsendbreak.lo: $(srcdir)/src/termios/tcsendbreak.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsetattr.lo: $(srcdir)/src/termios/tcsetattr.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcgetwinsize.lo: $(srcdir)/src/termios/tcgetwinsize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/termios/tcsetwinsize.lo: $(srcdir)/src/termios/tcsetwinsize.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__lock.lo: $(srcdir)/src/thread/__lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__set_thread_area.lo: $(srcdir)/src/thread/__set_thread_area.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/aarch64/__set_thread_area.lo: \
  $(srcdir)/src/thread/aarch64/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/arm/__set_thread_area.lo: \
  $(srcdir)/src/thread/arm/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sh/__set_thread_area.lo: \
  $(srcdir)/src/thread/sh/__set_thread_area.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__syscall_cp.lo: $(srcdir)/src/thread/__syscall_cp.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__timedwait.lo: $(srcdir)/src/thread/__timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__tls_get_addr.lo: $(srcdir)/src/thread/__tls_get_addr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__unmapself.lo: $(srcdir)/src/thread/__unmapself.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sh/__unmapself.lo: $(srcdir)/src/thread/sh/__unmapself.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/__wait.lo: $(srcdir)/src/thread/__wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/call_once.lo: $(srcdir)/src/thread/call_once.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/clone.lo: $(srcdir)/src/thread/clone.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_broadcast.lo: $(srcdir)/src/thread/cnd_broadcast.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_destroy.lo: $(srcdir)/src/thread/cnd_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_init.lo: $(srcdir)/src/thread/cnd_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_signal.lo: $(srcdir)/src/thread/cnd_signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_timedwait.lo: $(srcdir)/src/thread/cnd_timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/cnd_wait.lo: $(srcdir)/src/thread/cnd_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/default_attr.lo: $(srcdir)/src/thread/default_attr.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/lock_ptc.lo: $(srcdir)/src/thread/lock_ptc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_destroy.lo: $(srcdir)/src/thread/mtx_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_init.lo: $(srcdir)/src/thread/mtx_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_lock.lo: $(srcdir)/src/thread/mtx_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_timedlock.lo: $(srcdir)/src/thread/mtx_timedlock.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_trylock.lo: $(srcdir)/src/thread/mtx_trylock.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/mtx_unlock.lo: $(srcdir)/src/thread/mtx_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_atfork.lo: $(srcdir)/src/thread/pthread_atfork.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_destroy.lo: \
  $(srcdir)/src/thread/pthread_attr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_get.lo: $(srcdir)/src/thread/pthread_attr_get.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_init.lo: $(srcdir)/src/thread/pthread_attr_init.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setdetachstate.lo: \
  $(srcdir)/src/thread/pthread_attr_setdetachstate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setguardsize.lo: \
  $(srcdir)/src/thread/pthread_attr_setguardsize.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setinheritsched.lo: \
  $(srcdir)/src/thread/pthread_attr_setinheritsched.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setschedparam.lo: \
  $(srcdir)/src/thread/pthread_attr_setschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setschedpolicy.lo: \
  $(srcdir)/src/thread/pthread_attr_setschedpolicy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setscope.lo: \
  $(srcdir)/src/thread/pthread_attr_setscope.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setstack.lo: \
  $(srcdir)/src/thread/pthread_attr_setstack.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_attr_setstacksize.lo: \
  $(srcdir)/src/thread/pthread_attr_setstacksize.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_destroy.lo: \
  $(srcdir)/src/thread/pthread_barrier_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_init.lo: \
  $(srcdir)/src/thread/pthread_barrier_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrier_wait.lo: \
  $(srcdir)/src/thread/pthread_barrier_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_destroy.lo: \
  $(srcdir)/src/thread/pthread_barrierattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_init.lo: \
  $(srcdir)/src/thread/pthread_barrierattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_barrierattr_setpshared.lo: \
  $(srcdir)/src/thread/pthread_barrierattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cancel.lo: $(srcdir)/src/thread/pthread_cancel.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cleanup_push.lo: \
  $(srcdir)/src/thread/pthread_cleanup_push.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_broadcast.lo: \
  $(srcdir)/src/thread/pthread_cond_broadcast.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_destroy.lo: \
  $(srcdir)/src/thread/pthread_cond_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_init.lo: $(srcdir)/src/thread/pthread_cond_init.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_signal.lo: \
  $(srcdir)/src/thread/pthread_cond_signal.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_timedwait.lo: \
  $(srcdir)/src/thread/pthread_cond_timedwait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_cond_wait.lo: $(srcdir)/src/thread/pthread_cond_wait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_destroy.lo: \
  $(srcdir)/src/thread/pthread_condattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_init.lo: \
  $(srcdir)/src/thread/pthread_condattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_setclock.lo: \
  $(srcdir)/src/thread/pthread_condattr_setclock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_condattr_setpshared.lo: \
  $(srcdir)/src/thread/pthread_condattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_create.lo: $(srcdir)/src/thread/pthread_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_detach.lo: $(srcdir)/src/thread/pthread_detach.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_equal.lo: $(srcdir)/src/thread/pthread_equal.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getattr_np.lo: \
  $(srcdir)/src/thread/pthread_getattr_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getconcurrency.lo: \
  $(srcdir)/src/thread/pthread_getconcurrency.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getcpuclockid.lo: \
  $(srcdir)/src/thread/pthread_getcpuclockid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getname_np.lo: \
  $(srcdir)/src/thread/pthread_getname_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getschedparam.lo: \
  $(srcdir)/src/thread/pthread_getschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_getspecific.lo: \
  $(srcdir)/src/thread/pthread_getspecific.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_join.lo: $(srcdir)/src/thread/pthread_join.c \
   $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_key_create.lo: \
  $(srcdir)/src/thread/pthread_key_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_kill.lo: $(srcdir)/src/thread/pthread_kill.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_consistent.lo: \
  $(srcdir)/src/thread/pthread_mutex_consistent.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_destroy.lo: \
  $(srcdir)/src/thread/pthread_mutex_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_getprioceiling.lo: \
  $(srcdir)/src/thread/pthread_mutex_getprioceiling.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_init.lo: \
  $(srcdir)/src/thread/pthread_mutex_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_lock.lo: \
  $(srcdir)/src/thread/pthread_mutex_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_setprioceiling.lo: \
  $(srcdir)/src/thread/pthread_mutex_setprioceiling.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_timedlock.lo: \
  $(srcdir)/src/thread/pthread_mutex_timedlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_trylock.lo: \
  $(srcdir)/src/thread/pthread_mutex_trylock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutex_unlock.lo: \
  $(srcdir)/src/thread/pthread_mutex_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_destroy.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_init.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setprotocol.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_setprotocol.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setpshared.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_setrobust.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_setrobust.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_mutexattr_settype.lo: \
  $(srcdir)/src/thread/pthread_mutexattr_settype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_once.lo: $(srcdir)/src/thread/pthread_once.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_destroy.lo: \
  $(srcdir)/src/thread/pthread_rwlock_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_init.lo: \
  $(srcdir)/src/thread/pthread_rwlock_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_rdlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_rdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_timedrdlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_timedrdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_timedwrlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_timedwrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_tryrdlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_tryrdlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_trywrlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_trywrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_unlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlock_wrlock.lo: \
  $(srcdir)/src/thread/pthread_rwlock_wrlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_destroy.lo: \
  $(srcdir)/src/thread/pthread_rwlockattr_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_init.lo: \
  $(srcdir)/src/thread/pthread_rwlockattr_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_rwlockattr_setpshared.lo: \
  $(srcdir)/src/thread/pthread_rwlockattr_setpshared.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_self.lo: $(srcdir)/src/thread/pthread_self.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setattr_default_np.lo: \
  $(srcdir)/src/thread/pthread_setattr_default_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setcancelstate.lo: \
  $(srcdir)/src/thread/pthread_setcancelstate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setcanceltype.lo: \
  $(srcdir)/src/thread/pthread_setcanceltype.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setconcurrency.lo: \
  $(srcdir)/src/thread/pthread_setconcurrency.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setname_np.lo: \
  $(srcdir)/src/thread/pthread_setname_np.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setschedparam.lo: \
  $(srcdir)/src/thread/pthread_setschedparam.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setschedprio.lo: \
  $(srcdir)/src/thread/pthread_setschedprio.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_setspecific.lo: \
  $(srcdir)/src/thread/pthread_setspecific.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_sigmask.lo: \
  $(srcdir)/src/thread/pthread_sigmask.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_destroy.lo: \
  $(srcdir)/src/thread/pthread_spin_destroy.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_init.lo: \
  $(srcdir)/src/thread/pthread_spin_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_lock.lo: \
  $(srcdir)/src/thread/pthread_spin_lock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_trylock.lo: \
  $(srcdir)/src/thread/pthread_spin_trylock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_spin_unlock.lo: \
  $(srcdir)/src/thread/pthread_spin_unlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/pthread_testcancel.lo: \
  $(srcdir)/src/thread/pthread_testcancel.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_destroy.lo: $(srcdir)/src/thread/sem_destroy.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_getvalue.lo: $(srcdir)/src/thread/sem_getvalue.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_init.lo: $(srcdir)/src/thread/sem_init.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_open.lo: $(srcdir)/src/thread/sem_open.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_post.lo: $(srcdir)/src/thread/sem_post.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_timedwait.lo: $(srcdir)/src/thread/sem_timedwait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_trywait.lo: $(srcdir)/src/thread/sem_trywait.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_unlink.lo: $(srcdir)/src/thread/sem_unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/sem_wait.lo: $(srcdir)/src/thread/sem_wait.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/synccall.lo: $(srcdir)/src/thread/synccall.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/syscall_cp.lo: $(srcdir)/src/thread/syscall_cp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_create.lo: $(srcdir)/src/thread/thrd_create.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_exit.lo: $(srcdir)/src/thread/thrd_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_join.lo: $(srcdir)/src/thread/thrd_join.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_sleep.lo: $(srcdir)/src/thread/thrd_sleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/thrd_yield.lo: $(srcdir)/src/thread/thrd_yield.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tls.lo: $(srcdir)/src/thread/tls.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_create.lo: $(srcdir)/src/thread/tss_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_delete.lo: $(srcdir)/src/thread/tss_delete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/tss_set.lo: $(srcdir)/src/thread/tss_set.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/thread/vmlock.lo: $(srcdir)/src/thread/vmlock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__map_file.lo: $(srcdir)/src/time/__map_file.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__month_to_secs.lo: $(srcdir)/src/time/__month_to_secs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__secs_to_tm.lo: $(srcdir)/src/time/__secs_to_tm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__tm_to_secs.lo: $(srcdir)/src/time/__tm_to_secs.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__tz.lo: $(srcdir)/src/time/__tz.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__utc.lo: $(srcdir)/src/time/__utc.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/__year_to_secs.lo: $(srcdir)/src/time/__year_to_secs.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/asctime.lo: $(srcdir)/src/time/asctime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/asctime_r.lo: $(srcdir)/src/time/asctime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock.lo: $(srcdir)/src/time/clock.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_getcpuclockid.lo: $(srcdir)/src/time/clock_getcpuclockid.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_getres.lo: $(srcdir)/src/time/clock_getres.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_gettime.lo: $(srcdir)/src/time/clock_gettime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_nanosleep.lo: $(srcdir)/src/time/clock_nanosleep.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/clock_settime.lo: $(srcdir)/src/time/clock_settime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ctime.lo: $(srcdir)/src/time/ctime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ctime_r.lo: $(srcdir)/src/time/ctime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/difftime.lo: $(srcdir)/src/time/difftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/ftime.lo: $(srcdir)/src/time/ftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/getdate.lo: $(srcdir)/src/time/getdate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gettimeofday.lo: $(srcdir)/src/time/gettimeofday.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gmtime.lo: $(srcdir)/src/time/gmtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/gmtime_r.lo: $(srcdir)/src/time/gmtime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/localtime.lo: $(srcdir)/src/time/localtime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/localtime_r.lo: $(srcdir)/src/time/localtime_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/mktime.lo: $(srcdir)/src/time/mktime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/nanosleep.lo: $(srcdir)/src/time/nanosleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/strftime.lo: $(srcdir)/src/time/strftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/strptime.lo: $(srcdir)/src/time/strptime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/time.lo: $(srcdir)/src/time/time.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timegm.lo: $(srcdir)/src/time/timegm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_create.lo: $(srcdir)/src/time/timer_create.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_delete.lo: $(srcdir)/src/time/timer_delete.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_getoverrun.lo: $(srcdir)/src/time/timer_getoverrun.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_gettime.lo: $(srcdir)/src/time/timer_gettime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timer_settime.lo: $(srcdir)/src/time/timer_settime.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/times.lo: $(srcdir)/src/time/times.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/timespec_get.lo: $(srcdir)/src/time/timespec_get.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/utime.lo: $(srcdir)/src/time/utime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/time/wcsftime.lo: $(srcdir)/src/time/wcsftime.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/_exit.lo: $(srcdir)/src/unistd/_exit.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/access.lo: $(srcdir)/src/unistd/access.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/acct.lo: $(srcdir)/src/unistd/acct.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/alarm.lo: $(srcdir)/src/unistd/alarm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/chdir.lo: $(srcdir)/src/unistd/chdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/chown.lo: $(srcdir)/src/unistd/chown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/close.lo: $(srcdir)/src/unistd/close.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ctermid.lo: $(srcdir)/src/unistd/ctermid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup.lo: $(srcdir)/src/unistd/dup.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup2.lo: $(srcdir)/src/unistd/dup2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/dup3.lo: $(srcdir)/src/unistd/dup3.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/faccessat.lo: $(srcdir)/src/unistd/faccessat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchdir.lo: $(srcdir)/src/unistd/fchdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchown.lo: $(srcdir)/src/unistd/fchown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fchownat.lo: $(srcdir)/src/unistd/fchownat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fdatasync.lo: $(srcdir)/src/unistd/fdatasync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/fsync.lo: $(srcdir)/src/unistd/fsync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ftruncate.lo: $(srcdir)/src/unistd/ftruncate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getcwd.lo: $(srcdir)/src/unistd/getcwd.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getegid.lo: $(srcdir)/src/unistd/getegid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/geteuid.lo: $(srcdir)/src/unistd/geteuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getgid.lo: $(srcdir)/src/unistd/getgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getgroups.lo: $(srcdir)/src/unistd/getgroups.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/gethostname.lo: $(srcdir)/src/unistd/gethostname.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getlogin.lo: $(srcdir)/src/unistd/getlogin.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getlogin_r.lo: $(srcdir)/src/unistd/getlogin_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpgid.lo: $(srcdir)/src/unistd/getpgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpgrp.lo: $(srcdir)/src/unistd/getpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getpid.lo: $(srcdir)/src/unistd/getpid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getppid.lo: $(srcdir)/src/unistd/getppid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getsid.lo: $(srcdir)/src/unistd/getsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/getuid.lo: $(srcdir)/src/unistd/getuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/isatty.lo: $(srcdir)/src/unistd/isatty.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/lchown.lo: $(srcdir)/src/unistd/lchown.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/link.lo: $(srcdir)/src/unistd/link.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/linkat.lo: $(srcdir)/src/unistd/linkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/lseek.lo: $(srcdir)/src/unistd/lseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/mipsn32/lseek.lo: $(srcdir)/src/unistd/mipsn32/lseek.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/x32/lseek.lo: $(srcdir)/src/unistd/x32/lseek.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/nice.lo: $(srcdir)/src/unistd/nice.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pause.lo: $(srcdir)/src/unistd/pause.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pipe.lo: $(srcdir)/src/unistd/pipe.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pipe2.lo: $(srcdir)/src/unistd/pipe2.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/posix_close.lo: $(srcdir)/src/unistd/posix_close.c \
  $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pread.lo: $(srcdir)/src/unistd/pread.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/preadv.lo: $(srcdir)/src/unistd/preadv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pwrite.lo: $(srcdir)/src/unistd/pwrite.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/pwritev.lo: $(srcdir)/src/unistd/pwritev.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/read.lo: $(srcdir)/src/unistd/read.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readlink.lo: $(srcdir)/src/unistd/readlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readlinkat.lo: $(srcdir)/src/unistd/readlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/readv.lo: $(srcdir)/src/unistd/readv.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/renameat.lo: $(srcdir)/src/unistd/renameat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/rmdir.lo: $(srcdir)/src/unistd/rmdir.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setegid.lo: $(srcdir)/src/unistd/setegid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/seteuid.lo: $(srcdir)/src/unistd/seteuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setgid.lo: $(srcdir)/src/unistd/setgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setpgid.lo: $(srcdir)/src/unistd/setpgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setpgrp.lo: $(srcdir)/src/unistd/setpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setregid.lo: $(srcdir)/src/unistd/setregid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setresgid.lo: $(srcdir)/src/unistd/setresgid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setresuid.lo: $(srcdir)/src/unistd/setresuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setreuid.lo: $(srcdir)/src/unistd/setreuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setsid.lo: $(srcdir)/src/unistd/setsid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setuid.lo: $(srcdir)/src/unistd/setuid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/setxid.lo: $(srcdir)/src/unistd/setxid.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/sleep.lo: $(srcdir)/src/unistd/sleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/symlink.lo: $(srcdir)/src/unistd/symlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/symlinkat.lo: $(srcdir)/src/unistd/symlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/sync.lo: $(srcdir)/src/unistd/sync.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/tcgetpgrp.lo: $(srcdir)/src/unistd/tcgetpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/tcsetpgrp.lo: $(srcdir)/src/unistd/tcsetpgrp.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/truncate.lo: $(srcdir)/src/unistd/truncate.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ttyname.lo: $(srcdir)/src/unistd/ttyname.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ttyname_r.lo: $(srcdir)/src/unistd/ttyname_r.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/ualarm.lo: $(srcdir)/src/unistd/ualarm.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/unlink.lo: $(srcdir)/src/unistd/unlink.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/unlinkat.lo: $(srcdir)/src/unistd/unlinkat.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/usleep.lo: $(srcdir)/src/unistd/usleep.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/write.lo: $(srcdir)/src/unistd/write.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<
$(objbuilddir)/src/unistd/writev.lo: $(srcdir)/src/unistd/writev.c $(GENH) $(IMPH)
	$(CC_CMD) $@ $<

$(libbuilddir)/libc.so: $(LOBJS) $(LDSO_OBJS)
	$(CC) $(CFLAGS_ALL) $(LDFLAGS_ALL) -nostdlib -shared \
	  -Wl,-e,_dlstart -o $@ $(LOBJS) $(LDSO_OBJS) $(LIBCC)

$(libbuilddir)/libc.a: $(AOBJS)
	rm -f $@
	$(AR) rc $@ $(AOBJS)
	$(RANLIB) $@

$(EMPTY_LIBS):
	rm -f $@
	$(AR) rc $@

$(libbuilddir)/crti.o: $(objbuilddir)/crt/$(ARCH)/crti.o
	cp $< $@
$(libbuilddir)/crtn.o: $(objbuilddir)/crt/$(ARCH)/crtn.o
	cp $< $@

$(libbuilddir)/Scrt1.o: $(objbuilddir)/crt/Scrt1.o
	cp $< $@
$(libbuilddir)/crt1.o: $(objbuilddir)/crt/crt1.o
	cp $< $@
$(libbuilddir)/rcrt1.o: $(objbuilddir)/crt/rcrt1.o
	cp $< $@

$(libbuilddir)/musl-gcc.specs: $(srcdir)/tools/musl-gcc.specs.sh config.mak
	sh $< "$(includedir)" "$(libdir)" "$(LDSO_PATHNAME)" > $@

$(objbuilddir)/musl-gcc: config.mak
	printf \
	  '#!/bin/sh\nexec "%s" "%s" -specs "%s/musl-gcc.specs"\n' \
	  "$${REALGCC:-$(WRAPCC_GCC)}" "$$@" "$(libdir)" > $@
	chmod +x $@

$(objbuilddir)/ld.musl-clang.in $(objbuilddir)/musl-clang.in: \
  $(srcdir)/tools/ld.musl-clang.in $(srcdir)/tools/musl-clang.in config.mak
	sed -e 's!@CC@!$(WRAPCC_CLANG)!g' -e 's!@PREFIX@!$(prefix)!g' \
	  -e 's!@INCDIR@!$(includedir)!g' -e 's!@LIBDIR@!$(libdir)!g' \
	  -e 's!@LDSO@!$(LDSO_PATHNAME)!g' $< > $@
	chmod +x $@

$(DESTDIR)$(bindir)/musl-gcc: $(objbuilddir)/musl-gcc
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@

$(DESTDIR)$(libdir)/libc.so: $(libbuilddir)/libc.so
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 755 $@

$(DESTDIR)$(libdir)/Scrt1.o: $(libbuilddir)/Scrt1.o
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/crt1.o: $(libbuilddir)/crt1.o
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/crti.o: $(libbuilddir)/crti.o
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/crtn.o: $(libbuilddir)/crtn.o
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libc.a: $(libbuilddir)/libc.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libcrypt.a: $(libbuilddir)/libcrypt.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libdl.a: $(libbuilddir)/libdl.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libm.a: $(libbuilddir)/libm.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libpthread.a: $(libbuilddir)/libpthread.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libresolv.a: $(libbuilddir)/libresolv.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/librt.a: $(libbuilddir)/librt.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libutil.a: $(libbuilddir)/libutil.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/libxnet.a: $(libbuilddir)/libxnet.a
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/musl-gcc.specs: $(libbuilddir)/musl-gcc.specs
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(libdir)/rcrt1.o: $(libbuilddir)/rcrt1.o
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@

$(DESTDIR)$(includedir)/bits/alltypes.h.in: \
  $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/errno.h: \
  $(srcdir)/arch/generic/bits/errno.h $(srcdir)/arch/$(ARCH)/bits/errno.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/errno.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/errno.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/errno.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/fcntl.h: \
  $(srcdir)/arch/generic/bits/fcntl.h $(srcdir)/arch/$(ARCH)/bits/fcntl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/fcntl.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/fcntl.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/fcntl.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/fenv.h: \
  $(srcdir)/arch/generic/bits/fenv.h $(srcdir)/arch/$(ARCH)/bits/fenv.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/fenv.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/fenv.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/fenv.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/float.h: $(srcdir)/arch/$(ARCH)/bits/float.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/hwcap.h: \
  $(srcdir)/arch/generic/bits/hwcap.h $(srcdir)/arch/$(ARCH)/bits/hwcap.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/hwcap.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/hwcap.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/hwcap.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/io.h: \
  $(srcdir)/arch/generic/bits/io.h $(srcdir)/arch/$(ARCH)/bits/io.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/io.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/io.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/io.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/ioctl.h: \
  $(srcdir)/arch/generic/bits/ioctl.h $(srcdir)/arch/$(ARCH)/bits/ioctl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/ioctl.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/ioctl.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/ioctl.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/ioctl_fix.h: \
  $(srcdir)/arch/generic/bits/ioctl_fix.h \
  $(srcdir)/arch/$(ARCH)/bits/ioctl_fix.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/ioctl_fix.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/ioctl_fix.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/ioctl_fix.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/ipc.h: \
  $(srcdir)/arch/generic/bits/ipc.h $(srcdir)/arch/$(ARCH)/bits/ipc.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/ipc.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/ipc.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/ipc.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/ipcstat.h: \
  $(srcdir)/arch/generic/bits/ipcstat.h $(srcdir)/arch/$(ARCH)/bits/ipcstat.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/ipcstat.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/ipcstat.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/ipcstat.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/limits.h: \
  $(srcdir)/arch/generic/bits/limits.h $(srcdir)/arch/$(ARCH)/bits/limits.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/limits.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/limits.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/limits.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/link.h: \
  $(srcdir)/arch/generic/bits/link.h $(srcdir)/arch/$(ARCH)/bits/link.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/link.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/link.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/link.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/mman.h: \
  $(srcdir)/arch/generic/bits/mman.h $(srcdir)/arch/$(ARCH)/bits/mman.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/mman.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/mman.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/mman.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/msg.h: \
  $(srcdir)/arch/generic/bits/msg.h $(srcdir)/arch/$(ARCH)/bits/msg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/msg.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/msg.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/msg.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/poll.h: \
  $(srcdir)/arch/generic/bits/poll.h $(srcdir)/arch/$(ARCH)/bits/poll.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/poll.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/poll.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/poll.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/ptrace.h: \
  $(srcdir)/arch/generic/bits/ptrace.h $(srcdir)/arch/$(ARCH)/bits/ptrace.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/ptrace.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/ptrace.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/ptrace.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/reg.h: \
  $(srcdir)/arch/generic/bits/reg.h $(srcdir)/arch/$(ARCH)/bits/reg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/reg.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/reg.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/reg.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/resource.h: \
  $(srcdir)/arch/generic/bits/resource.h \
  $(srcdir)/arch/$(ARCH)/bits/resource.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/resource.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/resource.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/resource.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/sem.h: \
  $(srcdir)/arch/generic/bits/sem.h $(srcdir)/arch/$(ARCH)/bits/sem.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/sem.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/sem.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/sem.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/setjmp.h: $(srcdir)/arch/$(ARCH)/bits/setjmp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/shm.h: \
  $(srcdir)/arch/generic/bits/shm.h $(srcdir)/arch/$(ARCH)/bits/shm.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/shm.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/shm.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/shm.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/signal.h: $(srcdir)/arch/$(ARCH)/bits/signal.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/socket.h: \
  $(srcdir)/arch/generic/bits/socket.h $(srcdir)/arch/$(ARCH)/bits/socket.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/socket.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/socket.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/socket.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/stat.h: \
  $(srcdir)/arch/generic/bits/stat.h $(srcdir)/arch/$(ARCH)/bits/stat.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/stat.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/stat.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/stat.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/statfs.h: \
  $(srcdir)/arch/generic/bits/statfs.h $(srcdir)/arch/$(ARCH)/bits/statfs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/statfs.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/statfs.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/statfs.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/syscall.h.in: \
  $(srcdir)/arch/$(ARCH)/bits/syscall.h.in
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/termios.h: \
  $(srcdir)/arch/generic/bits/termios.h $(srcdir)/arch/$(ARCH)/bits/termios.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	if [ -f "$(srcdir)/arch/$(ARCH)/bits/termios.h" ]; then \
	    cp "$(srcdir)/arch/$(ARCH)/bits/termios.h" "$@"; \
	else \
	    cp "$(srcdir)/arch/generic/bits/termios.h" "$@"; \
	fi && chmod 644 $@
$(DESTDIR)$(includedir)/bits/user.h: $(srcdir)/arch/$(ARCH)/bits/user.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@

$(DESTDIR)$(includedir)/bits/dirent.h: $(srcdir)/arch/generic/bits/dirent.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/kd.h: $(srcdir)/arch/generic/bits/kd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/soundcard.h: \
  $(srcdir)/arch/generic/bits/soundcard.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/stdint.h: $(srcdir)/arch/generic/bits/stdint.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/vt.h: $(srcdir)/arch/generic/bits/vt.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@

$(DESTDIR)$(includedir)/bits/alltypes.h: $(objbuilddir)/include/bits/alltypes.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/bits/syscall.h: $(objbuilddir)/include/bits/syscall.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@

$(DESTDIR)$(includedir)/aio.h: $(srcdir)/include/aio.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/alloca.h: $(srcdir)/include/alloca.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/alltypes.h.in: $(srcdir)/include/alltypes.h.in
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ar.h: $(srcdir)/include/ar.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/ftp.h: $(srcdir)/include/arpa/ftp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/inet.h: $(srcdir)/include/arpa/inet.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/nameser.h: $(srcdir)/include/arpa/nameser.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/nameser_compat.h: \
  $(srcdir)/include/arpa/nameser_compat.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/telnet.h: $(srcdir)/include/arpa/telnet.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/arpa/tftp.h: $(srcdir)/include/arpa/tftp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/assert.h: $(srcdir)/include/assert.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/byteswap.h: $(srcdir)/include/byteswap.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/complex.h: $(srcdir)/include/complex.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/cpio.h: $(srcdir)/include/cpio.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/crypt.h: $(srcdir)/include/crypt.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ctype.h: $(srcdir)/include/ctype.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/dirent.h: $(srcdir)/include/dirent.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/dlfcn.h: $(srcdir)/include/dlfcn.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/elf.h: $(srcdir)/include/elf.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/endian.h: $(srcdir)/include/endian.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/err.h: $(srcdir)/include/err.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/errno.h: $(srcdir)/include/errno.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/fcntl.h: $(srcdir)/include/fcntl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/features.h: $(srcdir)/include/features.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/fenv.h: $(srcdir)/include/fenv.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/float.h: $(srcdir)/include/float.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/fmtmsg.h: $(srcdir)/include/fmtmsg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/fnmatch.h: $(srcdir)/include/fnmatch.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ftw.h: $(srcdir)/include/ftw.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/getopt.h: $(srcdir)/include/getopt.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/glob.h: $(srcdir)/include/glob.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/grp.h: $(srcdir)/include/grp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/iconv.h: $(srcdir)/include/iconv.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ifaddrs.h: $(srcdir)/include/ifaddrs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/inttypes.h: $(srcdir)/include/inttypes.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/iso646.h: $(srcdir)/include/iso646.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/langinfo.h: $(srcdir)/include/langinfo.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/lastlog.h: $(srcdir)/include/lastlog.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/libgen.h: $(srcdir)/include/libgen.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/libintl.h: $(srcdir)/include/libintl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/limits.h: $(srcdir)/include/limits.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/link.h: $(srcdir)/include/link.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/locale.h: $(srcdir)/include/locale.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/malloc.h: $(srcdir)/include/malloc.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/math.h: $(srcdir)/include/math.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/memory.h: $(srcdir)/include/memory.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/mntent.h: $(srcdir)/include/mntent.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/monetary.h: $(srcdir)/include/monetary.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/mqueue.h: $(srcdir)/include/mqueue.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/net/ethernet.h: $(srcdir)/include/net/ethernet.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/net/if.h: $(srcdir)/include/net/if.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/net/if_arp.h: $(srcdir)/include/net/if_arp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/net/route.h: $(srcdir)/include/net/route.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netdb.h: $(srcdir)/include/netdb.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/ether.h: $(srcdir)/include/netinet/ether.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/icmp6.h: $(srcdir)/include/netinet/icmp6.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/if_ether.h: \
  $(srcdir)/include/netinet/if_ether.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/igmp.h: $(srcdir)/include/netinet/igmp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/in.h: $(srcdir)/include/netinet/in.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/in_systm.h: \
  $(srcdir)/include/netinet/in_systm.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/ip.h: $(srcdir)/include/netinet/ip.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/ip_icmp.h: $(srcdir)/include/netinet/ip_icmp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/ip6.h: $(srcdir)/include/netinet/ip6.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/tcp.h: $(srcdir)/include/netinet/tcp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netinet/udp.h: $(srcdir)/include/netinet/udp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/netpacket/packet.h: \
  $(srcdir)/include/netpacket/packet.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/nl_types.h: $(srcdir)/include/nl_types.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/paths.h: $(srcdir)/include/paths.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/poll.h: $(srcdir)/include/poll.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/pthread.h: $(srcdir)/include/pthread.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/pty.h: $(srcdir)/include/pty.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/pwd.h: $(srcdir)/include/pwd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/regex.h: $(srcdir)/include/regex.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/resolv.h: $(srcdir)/include/resolv.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sched.h: $(srcdir)/include/sched.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/scsi/scsi.h: $(srcdir)/include/scsi/scsi.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/scsi/scsi_ioctl.h: $(srcdir)/include/scsi/scsi_ioctl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/scsi/sg.h: $(srcdir)/include/scsi/sg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/search.h: $(srcdir)/include/search.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/semaphore.h: $(srcdir)/include/semaphore.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/setjmp.h: $(srcdir)/include/setjmp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/shadow.h: $(srcdir)/include/shadow.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/signal.h: $(srcdir)/include/signal.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/spawn.h: $(srcdir)/include/spawn.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdalign.h: $(srcdir)/include/stdalign.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdarg.h: $(srcdir)/include/stdarg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdbool.h: $(srcdir)/include/stdbool.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdc-predef.h: $(srcdir)/include/stdc-predef.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stddef.h: $(srcdir)/include/stddef.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdint.h: $(srcdir)/include/stdint.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdio.h: $(srcdir)/include/stdio.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdio_ext.h: $(srcdir)/include/stdio_ext.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdlib.h: $(srcdir)/include/stdlib.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stdnoreturn.h: $(srcdir)/include/stdnoreturn.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/string.h: $(srcdir)/include/string.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/strings.h: $(srcdir)/include/strings.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/stropts.h: $(srcdir)/include/stropts.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/acct.h: $(srcdir)/include/sys/acct.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/auxv.h: $(srcdir)/include/sys/auxv.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/cachectl.h: $(srcdir)/include/sys/cachectl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/dir.h: $(srcdir)/include/sys/dir.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/epoll.h: $(srcdir)/include/sys/epoll.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/errno.h: $(srcdir)/include/sys/errno.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/eventfd.h: $(srcdir)/include/sys/eventfd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/fanotify.h: $(srcdir)/include/sys/fanotify.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/fcntl.h: $(srcdir)/include/sys/fcntl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/file.h: $(srcdir)/include/sys/file.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/fsuid.h: $(srcdir)/include/sys/fsuid.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/inotify.h: $(srcdir)/include/sys/inotify.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/io.h: $(srcdir)/include/sys/io.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/ioctl.h: $(srcdir)/include/sys/ioctl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/ipc.h: $(srcdir)/include/sys/ipc.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/kd.h: $(srcdir)/include/sys/kd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/klog.h: $(srcdir)/include/sys/klog.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/membarrier.h: $(srcdir)/include/sys/membarrier.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/mman.h: $(srcdir)/include/sys/mman.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/mount.h: $(srcdir)/include/sys/mount.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/msg.h: $(srcdir)/include/sys/msg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/mtio.h: $(srcdir)/include/sys/mtio.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/param.h: $(srcdir)/include/sys/param.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/personality.h: $(srcdir)/include/sys/personality.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/poll.h: $(srcdir)/include/sys/poll.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/prctl.h: $(srcdir)/include/sys/prctl.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/procfs.h: $(srcdir)/include/sys/procfs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/ptrace.h: $(srcdir)/include/sys/ptrace.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/quota.h: $(srcdir)/include/sys/quota.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/random.h: $(srcdir)/include/sys/random.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/reboot.h: $(srcdir)/include/sys/reboot.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/reg.h: $(srcdir)/include/sys/reg.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/resource.h: $(srcdir)/include/sys/resource.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/select.h: $(srcdir)/include/sys/select.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/sem.h: $(srcdir)/include/sys/sem.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/sendfile.h: $(srcdir)/include/sys/sendfile.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/shm.h: $(srcdir)/include/sys/shm.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/signalfd.h: $(srcdir)/include/sys/signalfd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/signal.h: $(srcdir)/include/sys/signal.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/socket.h: $(srcdir)/include/sys/socket.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/soundcard.h: $(srcdir)/include/sys/soundcard.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/stat.h: $(srcdir)/include/sys/stat.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/statfs.h: $(srcdir)/include/sys/statfs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/statvfs.h: $(srcdir)/include/sys/statvfs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/stropts.h: $(srcdir)/include/sys/stropts.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/swap.h: $(srcdir)/include/sys/swap.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/syscall.h: $(srcdir)/include/sys/syscall.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/sysinfo.h: $(srcdir)/include/sys/sysinfo.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/syslog.h: $(srcdir)/include/sys/syslog.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/sysmacros.h: $(srcdir)/include/sys/sysmacros.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/termios.h: $(srcdir)/include/sys/termios.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/time.h: $(srcdir)/include/sys/time.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/timeb.h: $(srcdir)/include/sys/timeb.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/timerfd.h: $(srcdir)/include/sys/timerfd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/times.h: $(srcdir)/include/sys/times.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/timex.h: $(srcdir)/include/sys/timex.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/ttydefaults.h: $(srcdir)/include/sys/ttydefaults.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/types.h: $(srcdir)/include/sys/types.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/ucontext.h: $(srcdir)/include/sys/ucontext.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/uio.h: $(srcdir)/include/sys/uio.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/un.h: $(srcdir)/include/sys/un.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/user.h: $(srcdir)/include/sys/user.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/utsname.h: $(srcdir)/include/sys/utsname.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/vfs.h: $(srcdir)/include/sys/vfs.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/vt.h: $(srcdir)/include/sys/vt.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sys/wait.h: $(srcdir)/include/sys/wait.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/xattr.h: $(srcdir)/include/sys/xattr.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/syscall.h: $(srcdir)/include/syscall.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/sysexits.h: $(srcdir)/include/sysexits.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/syslog.h: $(srcdir)/include/syslog.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/tar.h: $(srcdir)/include/tar.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/termios.h: $(srcdir)/include/termios.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/tgmath.h: $(srcdir)/include/tgmath.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/threads.h: $(srcdir)/include/threads.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/time.h: $(srcdir)/include/time.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/uchar.h: $(srcdir)/include/uchar.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ucontext.h: $(srcdir)/include/ucontext.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/ulimit.h: $(srcdir)/include/ulimit.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/unistd.h: $(srcdir)/include/unistd.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/utime.h: $(srcdir)/include/utime.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/utmp.h: $(srcdir)/include/utmp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/utmpx.h: $(srcdir)/include/utmpx.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/values.h: $(srcdir)/include/values.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/wait.h: $(srcdir)/include/wait.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/wchar.h: $(srcdir)/include/wchar.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/wctype.h: $(srcdir)/include/wctype.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@
$(DESTDIR)$(includedir)/wordexp.h: $(srcdir)/include/wordexp.h
	mkdir -p $$(dirname $@) 2>/dev/null || true
	cp $< $@ && chmod 644 $@

$(DESTDIR)$(LDSO_PATHNAME): $(DESTDIR)$(libdir)/libc.so
	mkdir -p $$(dirname $@) 2>/dev/null || true
	ln $(libdir)/libc.so $@ || true

INSTALL_LIBS != \
if [ "$(SHARED_LIBS)" ]; then \
    printf "%s\n" "$(DESTDIR)$(LDSO_PATHNAME)"; \
fi
install-libs: \
  $(ALL_LIBS:$(libbuilddir)/%=$(DESTDIR)$(libdir)/%) $(INSTALL_LIBS)

install-headers: $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%)

install-tools: $(ALL_TOOLS:$(objbuilddir)/%=$(DESTDIR)$(bindir)/%)

install: install-libs install-headers install-tools

VERSION != cat $(srcdir)/VERSION 2>/dev/null || true
musl-git-$(VERSION).tar.gz: .git
	git --git-dir=$(srcdir)/.git archive --format=tar.gz \
	  --prefix=$(@:%.tar.gz=%)/ -o $@ $(@:musl-git-%.tar.gz=%)

musl-$(VERSION).tar.gz: .git
	git --git-dir=$(srcdir)/.git archive --format=tar.gz \
	  --prefix=$(@:%.tar.gz=%)/ -o $@ v$(@:musl-%.tar.gz=%)

clean:
	rm -rf $(objbuilddir) $(libbuilddir)

distclean: clean
	rm -f config.mak

.PHONY: all arch clean install install-libs install-headers install-tools
