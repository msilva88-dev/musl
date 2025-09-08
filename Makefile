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
exec_prefix = /usr/local
bindir = $(exec_prefix)/bin

prefix = /usr/local/musl
includedir = $(prefix)/include
libdir = $(prefix)/lib
syslibdir = /lib

MALLOC_DIR = mallocng
SRC_DIRS = $(addprefix $(srcdir)/,src/* src/malloc/$(MALLOC_DIR) crt ldso $(COMPAT_SRC_DIRS))
BASE_GLOBS = $(addsuffix /*.c,$(SRC_DIRS))
ARCH_GLOBS = $(addsuffix /$(ARCH)/*.[csS],$(SRC_DIRS))
BASE_SRCS = $(sort $(wildcard $(BASE_GLOBS)))
ARCH_SRCS = $(sort $(wildcard $(ARCH_GLOBS)))
BASE_OBJS = $(patsubst $(srcdir)/%,%.o,$(basename $(BASE_SRCS)))
ARCH_OBJS = $(patsubst $(srcdir)/%,%.o,$(basename $(ARCH_SRCS)))
REPLACED_OBJS = $(sort $(subst /$(ARCH)/,/,$(ARCH_OBJS)))
ALL_OBJS = $(addprefix obj/, $(filter-out $(REPLACED_OBJS), $(sort $(BASE_OBJS) $(ARCH_OBJS))))

LIBC_OBJS = $(filter obj/src/%,$(ALL_OBJS)) $(filter obj/compat/%,$(ALL_OBJS))
LDSO_OBJS = $(filter obj/ldso/%,$(ALL_OBJS:%.o=%.lo))
CRT_OBJS = $(filter obj/crt/%,$(ALL_OBJS))

AOBJS = $(LIBC_OBJS)
LOBJS = $(LIBC_OBJS:.o=.lo)
GENH = obj/include/bits/alltypes.h obj/include/bits/syscall.h
GENH_INT = obj/src/internal/version.h
IMPH = $(addprefix $(srcdir)/, src/internal/stdio_impl.h src/internal/pthread_impl.h src/internal/locale_impl.h src/internal/libc.h)

LDFLAGS =
LDFLAGS_AUTO =
LIBCC = -lgcc
CPPFLAGS =
CFLAGS =
CFLAGS_AUTO = -Os -pipe
CFLAGS_C99FSE = -std=c99 -ffreestanding -nostdinc 

CFLAGS_ALL = $(CFLAGS_C99FSE)
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I$(srcdir)/arch/$(ARCH) -I$(srcdir)/arch/generic -Iobj/src/internal -I$(srcdir)/src/include -I$(srcdir)/src/internal -Iobj/include -I$(srcdir)/include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS_AUTO) $(CFLAGS)

LDFLAGS_ALL = $(LDFLAGS_AUTO) $(LDFLAGS)

AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib
INSTALL = $(srcdir)/tools/install.sh

ARCH_INCLUDES = $(wildcard $(srcdir)/arch/$(ARCH)/bits/*.h)
GENERIC_INCLUDES = $(wildcard $(srcdir)/arch/generic/bits/*.h)
INCLUDES = $(wildcard $(srcdir)/include/*.h $(srcdir)/include/*/*.h)
ALL_INCLUDES = $(sort $(INCLUDES:$(srcdir)/%=%) $(GENH:obj/%=%) $(ARCH_INCLUDES:$(srcdir)/arch/$(ARCH)/%=include/%) $(GENERIC_INCLUDES:$(srcdir)/arch/generic/%=include/%))

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=lib/lib%.a)
CRT_LIBS = $(addprefix lib/,$(notdir $(CRT_OBJS)))
STATIC_LIBS = lib/libc.a
SHARED_LIBS = lib/libc.so
TOOL_LIBS = lib/musl-gcc.specs
ALL_LIBS = $(CRT_LIBS) $(STATIC_LIBS) $(SHARED_LIBS) $(EMPTY_LIBS) $(TOOL_LIBS)
ALL_TOOLS = obj/musl-gcc

WRAPCC_GCC = gcc
WRAPCC_CLANG = clang

LDSO_PATHNAME = $(syslibdir)/ld-musl-$(ARCH)$(SUBARCH).so.1

-include config.mak
-include $(srcdir)/arch/$(ARCH)/arch.mak

# --- Experimental OpenBSD hook (stage-1: static, single-thread) -------
# NOTE: This block must come *after* the includes above so:
#   - config.mak has defined TARGET_OS=openbsd
#   - SRCS is fully populated (so filtering is effective)
ifeq ($(TARGET_OS),openbsd)

# Ensure the OpenBSD overlay really comes first: remove any earlier
# -Iarch/$(ARCH) and append it after the overlay path we just added.
# (Use $(srcdir) to match how arch paths are formed elsewhere.)
CPPFLAGS := -I$(srcdir)/arch/openbsd/$(ARCH) \
	$(filter-out -I$(srcdir)/arch/$(ARCH),$(CPPFLAGS)) \
	-I$(srcdir)/arch/$(ARCH)

# Do not add /usr/include globally: it can cause system headers (e.g.
# <endian.h>) to override musl's. The OpenBSD overlay pulls in only the
# needed kernel numbers directly (see bits/syscall.h).

# Stage-1 bootstrap is static-only; we are not building ldso/threads yet.
# (This only affects binaries linked during the build; libc.a contents are PIC as usual.)
LDFLAGS  := -static $(LDFLAGS)

# Make sure the OpenBSD overlay is searched *before* arch/$(ARCH) in the
# actual compile flags. CFLAGS_ALL hard-codes -Iarch/$(ARCH) ahead of
# $(CPPFLAGS), so adjust CFLAGS_ALL ordering here.
CFLAGS_ALL := -I$(srcdir)/arch/openbsd/$(ARCH) \
	$(filter-out -I$(srcdir)/arch/$(ARCH),$(CFLAGS_ALL)) \
	-I$(srcdir)/arch/$(ARCH)

# Ensure the kernel syscall header is visible despite -nostdinc.
# We only add a *system* include path here; musl's own -I paths still
# precede it in CFLAGS_ALL, so musl headers win for generic includes.
CPPFLAGS += -isystem /usr/include
CFLAGS_ALL += -isystem /usr/include

# Make sure the OpenBSD overlay is searched *before* arch/$(ARCH) in the
# actual compile flags. CFLAGS_ALL hard-codes -Iarch/$(ARCH) ahead of
# $(CPPFLAGS), so adjust CFLAGS_ALL ordering here.
CFLAGS_ALL := -I$(srcdir)/arch/openbsd/$(ARCH) \
	$(filter-out -I$(srcdir)/arch/$(ARCH),$(CFLAGS_ALL)) \
	-I$(srcdir)/arch/$(ARCH)

# Avoid building the generic getrandom so the OpenBSD version wins.
# (Filter both .o and .lo in case shared objects are ever built.)
ALL_OBJS := $(filter-out obj/src/misc/getrandom.o obj/src/misc/getrandom.lo,$(ALL_OBJS))

# Drop Linux-only sources entirely for Stage-1.
# Filtering at the object level ensures nothing under src/linux/ is compiled.
ALL_OBJS := $(filter-out obj/src/linux/%,$(ALL_OBJS))

# Also drop subsystems that depend on Linux interfaces or threads:
#  - AIO uses rt_* signal syscalls on Linux
#  - thread/ uses futex
#  - signal/ uses rt_* signal syscalls on Linux
# (These will be reintroduced in later stages with OpenBSD-specific shims.)
ALL_OBJS := $(filter-out obj/src/aio/%,$(ALL_OBJS))
ALL_OBJS := $(filter-out obj/src/thread/%,$(ALL_OBJS))
ALL_OBJS := $(filter-out obj/src/signal/%,$(ALL_OBJS))

# Tell the bits/syscall.h rule to use the OpenBSD overlay header
# instead of generating from the Linux .in file.
SYSCALL_BITS_SRC := $(srcdir)/arch/openbsd/$(ARCH)/bits/syscall.h
SYSCALL_BITS_RULE := overlay

# Use the OpenBSD-specific sysconf() and drop the generic one which
# references Linux-only interfaces (sched_getaffinity, etc).
ALL_OBJS := $(filter-out obj/src/conf/sysconf.o obj/src/conf/sysconf.lo,$(ALL_OBJS))
# (src/conf/sysconf_openbsd.c will be picked up automatically.)

# Mark stage-1 and enable OpenBSD feature macros
CFLAGS   += -DMUSL_OBSD -DMUSL_STATIC_ONLY -D_OPENBSD_SOURCE -U__linux__
CPPFLAGS += -DMUSL_OBSD -DMUSL_STATIC_ONLY -D_OPENBSD_SOURCE -U__linux__

# CFLAGS_ALL was formed earlier using :=. Pull in the *current*
# CPPFLAGS/CFLAGS (now containing -DMUSL_OBSD) so every TU sees it.
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS)

# Use the OpenBSD overlay to generate bits/syscall.h instead of the
# Linux template. The recipe below will honor this via SYSCALL_BITS_RULE.
SYSCALL_BITS_SRC  := $(srcdir)/arch/openbsd/$(ARCH)/bits/syscall.h
SYSCALL_BITS_RULE := overlay

# Use OpenBSD-specific getrlimit/setrlimit; the generic ones use
# Linux prlimit64 which does not exist here.
ALL_OBJS := $(filter-out obj/src/misc/getrlimit.o obj/src/misc/getrlimit.lo,$(ALL_OBJS))
ALL_OBJS := $(filter-out obj/src/misc/setrlimit.o obj/src/misc/setrlimit.lo,$(ALL_OBJS))
# (getrlimit_openbsd.c / setrlimit_openbsd.c will be picked up automatically)

# setdomainname(3) is Linux-only; use an OpenBSD stub and drop the
# generic implementation that calls SYS_setdomainname.
ALL_OBJS := $(filter-out obj/src/misc/setdomainname.o obj/src/misc/setdomainname.lo,$(ALL_OBJS))
# (src/misc/setdomainname_openbsd.c will be picked up automatically.)

# uname(): no Linux SYS_uname on OpenBSD — use sysctl-based version.
ALL_OBJS := $(filter-out obj/src/misc/uname.o obj/src/misc/uname.lo,$(ALL_OBJS))
# (src/misc/uname_openbsd.c will be picked up automatically.)

# Filter out Linux-only sources and any generic getrandom implementation,
# so src/misc/getrandom_openbsd.c is the sole provider.
SRCS := $(filter-out src/linux/%,$(SRCS))
SRCS := $(filter-out src/misc/getrandom.c,$(SRCS))

# mincore(): Linux-only SYS_mincore in generic file. Use OpenBSD stub and
# drop the Linux implementation from the object list for Stage-1.
ALL_OBJS := $(filter-out obj/src/mman/mincore.o obj/src/mman/mincore.lo,$(ALL_OBJS))
# (src/mman/mincore_openbsd.c will be picked up automatically.)

# mremap(): Linux-only; provide OpenBSD stub and drop the generic one.
ALL_OBJS := $(filter-out obj/src/mman/mremap.o obj/src/mman/mremap.lo,$(ALL_OBJS))
# (src/mman/mremap_openbsd.c will be picked up automatically.)

# POSIX message queues are not provided via SYS_mq_* on OpenBSD.
# Drop the Linux mq implementation and use stubs for stage-1.
ALL_OBJS := $(filter-out obj/src/mq/%.o obj/src/mq/%.lo,$(ALL_OBJS))
# (src/misc/mq_openbsd_stub.c supplies ENOSYS stubs.)

# recvmmsg/sendmmsg are Linux-only; use OpenBSD stubs for Stage-1
# and drop the generic Linux objects from the build.
ALL_OBJS := $(filter-out \
  obj/src/network/recvmmsg.o obj/src/network/recvmmsg.lo \
  obj/src/network/sendmmsg.o obj/src/network/sendmmsg.lo, \
  $(ALL_OBJS))
# (src/network/recvmmsg_openbsd.c and sendmmsg_openbsd.c will be picked up
#  automatically by the toplevel source globs.)

# _Fork: Linux version uses SYS_set_tid_address. Use OpenBSD variant.
ALL_OBJS := $(filter-out obj/src/process/_Fork.o obj/src/process/_Fork.lo, \
  $(ALL_OBJS))
# (src/process/_Fork_openbsd.c will be picked up automatically.)

# fexecve(): Linux version uses execveat; use OpenBSD variant instead.
ALL_OBJS := $(filter-out obj/src/process/fexecve.o obj/src/process/fexecve.lo, \
  $(ALL_OBJS))
# (src/process/fexecve_openbsd.c will be picked up automatically.)

# waitid(): Linux-only SYS_waitid; use OpenBSD stub for stage-1.
ALL_OBJS := $(filter-out obj/src/process/waitid.o obj/src/process/waitid.lo, \
  $(ALL_OBJS))
# (src/process/waitid_openbsd.c will be picked up automatically.)

# CPU affinity is not available on OpenBSD; use stubs for Stage-1 and
# drop the Linux implementations that reference SYS_sched_*affinity.
ALL_OBJS := $(filter-out \
  obj/src/sched/sched_setaffinity.o obj/src/sched/sched_setaffinity.lo \
  obj/src/sched/sched_getaffinity.o obj/src/sched/sched_getaffinity.lo, \
  $(ALL_OBJS))

# Linux sched_cpucount pulls in affinity.c (uses SYS_sched_setaffinity).
# For OpenBSD stage-1, drop both and supply a portable __sched_cpucount().
ALL_OBJS := $(filter-out \
  obj/src/sched/affinity.o obj/src/sched/affinity.lo \
  obj/src/sched/sched_cpucount.o obj/src/sched/sched_cpucount.lo, \
  $(ALL_OBJS))
# (src/sched/sched_cpucount_openbsd.c is picked up automatically.)

# sched_get_priority_{max,min}: Linux-only syscalls in generic sources.
# Use OpenBSD shims and drop the Linux objects.
ALL_OBJS := $(filter-out \
  obj/src/sched/sched_get_priority_max.o obj/src/sched/sched_get_priority_max.lo \
  obj/src/sched/sched_get_priority_min.o obj/src/sched/sched_get_priority_min.lo, \
  $(ALL_OBJS))
# (openbsd variants are picked up automatically.)

# sched_getcpu(): Linux-only SYS_getcpu; use OpenBSD stub for Stage-1.
ALL_OBJS := $(filter-out \
  obj/src/sched/sched_getcpu.o obj/src/sched/sched_getcpu.lo, \
  $(ALL_OBJS))

# sched_rr_get_interval(): Linux-only syscall; use OpenBSD stub.
ALL_OBJS := $(filter-out \
  obj/src/sched/sched_rr_get_interval.o obj/src/sched/sched_rr_get_interval.lo, \
  $(ALL_OBJS))

# select()/pselect(): Linux versions use pselect6(_time64).
# Use OpenBSD syscalls instead and drop the Linux objects.
ALL_OBJS := $(filter-out \
  obj/src/select/select.o  obj/src/select/select.lo  \
  obj/src/select/pselect.o obj/src/select/pselect.lo, \
  $(ALL_OBJS))
# (openbsd variants below are picked up by the toplevel source globs.)

# fchmodat(): Linux generic uses SYS_fchmodat2; use OpenBSD syscall.
ALL_OBJS := $(filter-out \
  obj/src/stat/fchmodat.o obj/src/stat/fchmodat.lo, \
  $(ALL_OBJS))

# statx(): Linux-only. Use an OpenBSD stub for Stage-1.
ALL_OBJS := $(filter-out \
  obj/src/stat/statx.o obj/src/stat/statx.lo, \
  $(ALL_OBJS))

# fstatat(): drop Linux object that routes via statx(2); we provide
# src/stat/fstatat_openbsd.c instead.
ALL_OBJS := $(filter-out \
  obj/src/stat/fstatat.o obj/src/stat/fstatat.lo, \
  $(ALL_OBJS))

# clock_nanosleep(): Linux uses SYS_clock_nanosleep_time64.
# Use our OpenBSD libc implementation instead.
ALL_OBJS := $(filter-out \
  obj/src/time/clock_nanosleep.o obj/src/time/clock_nanosleep.lo, \
  $(ALL_OBJS))

# POSIX timers: use ENOSYS stubs on OpenBSD for stage-1.
ALL_OBJS := $(filter-out \
  obj/src/time/timer_create.o      obj/src/time/timer_create.lo      \
  obj/src/time/timer_delete.o      obj/src/time/timer_delete.lo      \
  obj/src/time/timer_getoverrun.o  obj/src/time/timer_getoverrun.lo  \
  obj/src/time/timer_gettime.o     obj/src/time/timer_gettime.lo     \
  obj/src/time/timer_settime.o     obj/src/time/timer_settime.lo,    \
  $(ALL_OBJS))

# times(): Linux uses SYS_times. Use our OpenBSD libc implementation.
ALL_OBJS := $(filter-out \
  obj/src/time/times.o obj/src/time/times.lo, \
  $(ALL_OBJS))

# faccessat(): Linux uses faccessat2; use OpenBSD faccessat(2) instead.
ALL_OBJS := $(filter-out \
  obj/src/unistd/faccessat.o obj/src/unistd/faccessat.lo, \
  $(ALL_OBJS))

# fdatasync(): OpenBSD has no SYS_fdatasync; map to fsync(2).
ALL_OBJS := $(filter-out \
  obj/src/unistd/datasync.o obj/src/unistd/datasync.lo, \
  $(ALL_OBJS))

endif
# ----------------------------------------------------------------------

ifeq ($(ARCH),)

all:
	@echo "Please set ARCH in config.mak before running make."
	@exit 1

else

all: $(ALL_LIBS) $(ALL_TOOLS)

OBJ_DIRS = $(sort $(patsubst %/,%,$(dir $(ALL_LIBS) $(ALL_TOOLS) $(ALL_OBJS) $(GENH) $(GENH_INT))) obj/include)

$(ALL_LIBS) $(ALL_TOOLS) $(ALL_OBJS) $(ALL_OBJS:%.o=%.lo) $(GENH) $(GENH_INT): | $(OBJ_DIRS)

$(OBJ_DIRS):
	mkdir -p $@

obj/include/bits/alltypes.h: $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in $(srcdir)/include/alltypes.h.in $(srcdir)/tools/mkalltypes.sed
	sed -f $(srcdir)/tools/mkalltypes.sed $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in $(srcdir)/include/alltypes.h.in > $@

# Use overlay on OpenBSD; otherwise generate from the .in file.
obj/include/bits/syscall.h: $(if $(filter overlay,$(SYSCALL_BITS_RULE)),$(SYSCALL_BITS_SRC),$(srcdir)/arch/$(ARCH)/bits/syscall.h.in)
	cp $< $@
ifneq ($(SYSCALL_BITS_RULE),overlay)
	sed -n -e s/__NR_/SYS_/p < $< >> $@
endif

obj/src/internal/version.h: $(wildcard $(srcdir)/VERSION $(srcdir)/.git)
	printf '#define VERSION "%s"\n' "$$(cd $(srcdir); sh tools/version.sh)" > $@

obj/src/internal/version.o obj/src/internal/version.lo: obj/src/internal/version.h

obj/crt/rcrt1.o obj/ldso/dlstart.lo obj/ldso/dynlink.lo: $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h

obj/crt/crt1.o obj/crt/scrt1.o obj/crt/rcrt1.o obj/ldso/dlstart.lo: $(srcdir)/arch/$(ARCH)/crt_arch.h

obj/crt/rcrt1.o: $(srcdir)/ldso/dlstart.c

obj/crt/Scrt1.o obj/crt/rcrt1.o: CFLAGS_ALL += -fPIC

OPTIMIZE_SRCS = $(wildcard $(OPTIMIZE_GLOBS:%=$(srcdir)/src/%))
$(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.o) $(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.lo): CFLAGS += -O3

MEMOPS_OBJS = $(filter %/memcpy.o %/memmove.o %/memcmp.o %/memset.o, $(LIBC_OBJS))
$(MEMOPS_OBJS) $(MEMOPS_OBJS:%.o=%.lo): CFLAGS_ALL += $(CFLAGS_MEMOPS)

NOSSP_OBJS = $(CRT_OBJS) $(LDSO_OBJS) $(filter \
	%/__libc_start_main.o %/__init_tls.o %/__stack_chk_fail.o \
	%/__set_thread_area.o %/memset.o %/memcpy.o \
	, $(LIBC_OBJS))
$(NOSSP_OBJS) $(NOSSP_OBJS:%.o=%.lo): CFLAGS_ALL += $(CFLAGS_NOSSP)

$(CRT_OBJS): CFLAGS_ALL += -DCRT

$(LOBJS) $(LDSO_OBJS): CFLAGS_ALL += -fPIC

CC_CMD = $(CC) $(CFLAGS_ALL) -c -o $@ $<

# Choose invocation of assembler to be used
ifeq ($(ADD_CFI),yes)
	AS_CMD = LC_ALL=C awk -f $(srcdir)/tools/add-cfi.common.awk -f $(srcdir)/tools/add-cfi.$(ARCH).awk $< | $(CC) $(CFLAGS_ALL) -x assembler -c -o $@ -
else
	AS_CMD = $(CC_CMD)
endif

obj/%.o: $(srcdir)/%.s
	$(AS_CMD)

obj/%.o: $(srcdir)/%.S
	$(CC_CMD)

obj/%.o: $(srcdir)/%.c $(GENH) $(IMPH)
	$(CC_CMD)

obj/%.lo: $(srcdir)/%.s
	$(AS_CMD)

obj/%.lo: $(srcdir)/%.S
	$(CC_CMD)

obj/%.lo: $(srcdir)/%.c $(GENH) $(IMPH)
	$(CC_CMD)

lib/libc.so: $(LOBJS) $(LDSO_OBJS)
	$(CC) $(CFLAGS_ALL) $(LDFLAGS_ALL) -nostdlib -shared \
	-Wl,-e,_dlstart -o $@ $(LOBJS) $(LDSO_OBJS) $(LIBCC)

lib/libc.a: $(AOBJS)
	rm -f $@
	$(AR) rc $@ $(AOBJS)
	$(RANLIB) $@

$(EMPTY_LIBS):
	rm -f $@
	$(AR) rc $@

lib/%.o: obj/crt/$(ARCH)/%.o
	cp $< $@

lib/%.o: obj/crt/%.o
	cp $< $@

lib/musl-gcc.specs: $(srcdir)/tools/musl-gcc.specs.sh config.mak
	sh $< "$(includedir)" "$(libdir)" "$(LDSO_PATHNAME)" > $@

obj/musl-gcc: config.mak
	printf '#!/bin/sh\nexec "$${REALGCC:-$(WRAPCC_GCC)}" "$$@" -specs "%s/musl-gcc.specs"\n' "$(libdir)" > $@
	chmod +x $@

obj/%-clang: $(srcdir)/tools/%-clang.in config.mak
	sed -e 's!@CC@!$(WRAPCC_CLANG)!g' -e 's!@PREFIX@!$(prefix)!g' -e 's!@INCDIR@!$(includedir)!g' -e 's!@LIBDIR@!$(libdir)!g' -e 's!@LDSO@!$(LDSO_PATHNAME)!g' $< > $@
	chmod +x $@

$(DESTDIR)$(bindir)/%: obj/%
	$(INSTALL) -D $< $@

$(DESTDIR)$(libdir)/%.so: lib/%.so
	$(INSTALL) -D -m 755 $< $@

$(DESTDIR)$(libdir)/%: lib/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: $(srcdir)/arch/$(ARCH)/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: $(srcdir)/arch/generic/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: obj/include/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/%: $(srcdir)/include/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(LDSO_PATHNAME): $(DESTDIR)$(libdir)/libc.so
	$(INSTALL) -D -l $(libdir)/libc.so $@ || true

install-libs: $(ALL_LIBS:lib/%=$(DESTDIR)$(libdir)/%) $(if $(SHARED_LIBS),$(DESTDIR)$(LDSO_PATHNAME),)

install-headers: $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%)

install-tools: $(ALL_TOOLS:obj/%=$(DESTDIR)$(bindir)/%)

install: install-libs install-headers install-tools

musl-git-%.tar.gz: .git
	 git --git-dir=$(srcdir)/.git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ $(patsubst musl-git-%.tar.gz,%,$@)

musl-%.tar.gz: .git
	 git --git-dir=$(srcdir)/.git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ v$(patsubst musl-%.tar.gz,%,$@)

endif

clean:
	rm -rf obj lib

distclean: clean
	rm -f config.mak

.PHONY: all clean install install-libs install-headers install-tools
