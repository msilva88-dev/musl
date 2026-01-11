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

UNAME != \
if [ "$(CROSS_COMPILE)" ]; then \
    case "$(CROSS_COMPILE)" in \
        *-hyperbolabsd*) printf "%s\n" "HyperbolaBSD" ;; \
        *-linux-musl*) printf "%s\n" "Linux" ;; \
        *-openbsd*) printf "%s\n" "OpenBSD" ;; \
    esac; \
else \
    printf "%s\n" "$$(uname -s)"; \
fi

BSDARCH = $(shell echo $(ARCH) | tr a-z A-Z)
ifeq ($(ARCH),x86_64)
BSDARCH = AMD64
endif

MALLOC_DIR = malloc_mchunk
COMMON_DIRS = src/aio src/complex src/conf src/crypt src/ctype src/dirent
COMMON_DIRS += src/env src/errno src/exit src/fcntl src/fenv src/include
COMMON_DIRS += src/internal src/ipc src/ldso src/legacy src/locale src/malloc
COMMON_DIRS += src/math src/misc src/mman src/mq src/multibyte src/network
COMMON_DIRS += src/passwd src/prng src/process src/regex src/sched src/search
COMMON_DIRS += src/select src/setjmp src/signal src/stat src/stdio src/stdlib
COMMON_DIRS += src/string src/temp src/termios src/thread src/time src/unistd

ifeq ($(filter $(UNAME),HyperbolaBSD OpenBSD),$(UNAME))
TARGET_DIR = src/bsd
else ifeq ($(filter $(UNAME),Linux),$(UNAME))
TARGET_DIR = src/linux
endif

SRC_DIRS = $(addprefix $(srcdir)/,$(COMMON_DIRS) $(TARGET_DIR) src/malloc/$(MALLOC_DIR) crt ldso $(COMPAT_SRC_DIRS))
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
ifeq ($(filter $(UNAME),HyperbolaBSD OpenBSD),$(UNAME))
ifeq ($(filter $(ARCH),i386 x32 x86_64),$(ARCH))
GENH += obj/include/bits/sysarch.h
endif
endif
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
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I$(srcdir)/arch/$(ARCH) -I$(srcdir)/arch/generic
CFLAGS_ALL += -Iobj/src/internal -I$(srcdir)/src/include -I$(srcdir)/src/internal -Iobj/include -I$(srcdir)/include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS_AUTO) $(CFLAGS)

LDFLAGS_ALL = $(LDFLAGS_AUTO) $(LDFLAGS)

AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib
INSTALL = $(srcdir)/tools/install.sh

COMMON_HEADERS = $(wildcard include/*.h)
COMMON_HEADERS += $(wildcard include/arpa/*.h)
COMMON_HEADERS += $(wildcard include/net/*.h)
COMMON_HEADERS += $(wildcard include/netinet/*.h)
COMMON_HEADERS += $(wildcard include/netpacket/*.h)
COMMON_HEADERS += $(wildcard include/scsi/*.h)
COMMON_HEADERS += sys/auxv.h sys/mount.h sys/reboot.h sys/swap.h sys/syscall.h sys/wait.h
BSD_HEADERS = sys/event.h sys/gmon.h sys/mount_info.h sys/sysarch.h
HBBSD_HEADERS = $(BSD_HEADERS)
LINUX_HEADERS = mqueue.h sys/epoll.h sys/eventfd.h sys/fanotify.h sys/inotify.h sys/io.h sys/klog.h sys/membarrier.h
LINUX_HEADERS += sys/personality.h sys/prctl.h sys/random.h sys/signalfd.h sys/sysinfo.h sys/timerfd.h sys/timex.h sys/xattr.h
OBSD_HEADERS = $(BSD_HEADERS)
ARCH_INCLUDES = $(wildcard $(srcdir)/arch/$(ARCH)/bits/*.h)
GENERIC_INCLUDES = $(wildcard $(srcdir)/arch/generic/bits/*.h)
ifeq ($(UNAME),HyperbolaBSD)
INCLUDES = $(COMMON_HEADERS) $(HBBSD_HEADERS)
ARCH_SYSCALL_HEADER = $(srcdir)/arch/generic/bits/syscall.h.in
else ifeq ($(UNAME),Linux)
INCLUDES = $(COMMON_HEADERS) $(LINUX_HEADERS)
ARCH_SYSCALL_HEADER = $(srcdir)/arch/$(ARCH)/bits/syscall.h.in
else ifeq ($(UNAME),OpenBSD)
INCLUDES = $(COMMON_HEADERS) $(OBSD_HEADERS)
ARCH_SYSCALL_HEADER = $(srcdir)/arch/generic/bits/syscall.h.in
endif
ALL_INCLUDES = $(sort $(INCLUDES:$(srcdir)/%=%) $(GENH:obj/%=%) \
 $(ARCH_INCLUDES:$(srcdir)/arch/$(ARCH)/%=include/%) $(GENERIC_INCLUDES:$(srcdir)/arch/generic/%=include/%))

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

obj/include/bits/sysarch.h: $(srcdir)/arch/$(ARCH)/bits/sysarch.h.in
	cp $< $@
	sed -n -e s/__NR_/$(BSDARCH)_/p < $< >> $@

obj/include/bits/syscall.h: $(ARCH_SYSCALL_HEADER)
	cp $< $@
	sed -n -e s/__NR_/SYS_/p < $< >> $@

obj/src/internal/version.h: $(wildcard $(srcdir)/VERSION $(srcdir)/.git)
	printf '#define VERSION "%s"\n' "$$(cd $(srcdir); sh tools/version.sh)" > $@

obj/src/internal/version.o obj/src/internal/version.lo: obj/src/internal/version.h

obj/crt/rcrt1.o obj/ldso/dlstart.lo obj/ldso/dynlink.lo: $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h

obj/crt/crt1.o obj/crt/Scrt1.o obj/crt/rcrt1.o obj/ldso/dlstart.lo: $(srcdir)/arch/$(ARCH)/crt_arch.h

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
	AS_CMD = LC_ALL=C awk -f $(srcdir)/tools/add-cfi.common.awk
	AS_CMD += -f $(srcdir)/tools/add-cfi.$(ARCH).awk $< | $(CC) $(CFLAGS_ALL) -x assembler -c -o $@ -
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
