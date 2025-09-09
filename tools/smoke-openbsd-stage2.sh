#!/bin/sh
# Tiny OpenBSD stage-2 smoke: build libc.so + ldso and run a dynamic hello
set -euo pipefail

echo "[$0] building shared libc and ldso..."
${MAKE:-gmake} -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" lib/libc.so
# libc.so already contains the loader; just ensure the expected soname symlink
${MAKE:-gmake} ldso-symlink

# Ensure we have the loader name musl expects
mkdir -p lib
arch="$(uname -m)"
case "$arch" in
  amd64|x86_64) ldname="ld-musl-x86_64.so.1" ;;
  *) echo "unsupported arch for this smoke: $arch" >&2; exit 1 ;;
esac
[ -e "lib/$ldname" ] || ln -sf libc.so "lib/$ldname"

# Prefer ports gcc if available; otherwise fall back to cc
: "${CC:=$(command -v egcc 2>/dev/null || echo cc)}"

cat > /tmp/dhello.c <<'C'
#include <unistd.h>
int main(){ const char s[]="hello (dynamic) from musl/obsd\n"; write(1,s,sizeof s-1); }
C
echo "[$0] linking dynamic hello against ./lib (embed loader)..."
# Embed our loader path and rpath so we can run the binary directly.
"$CC" -fPIC -o /tmp/dhello /tmp/dhello.c \
  -Wl,-rpath,"$PWD/lib" \
  -Wl,-dynamic-linker,"$PWD/lib/$ldname" \
  -L./lib -lc

echo "----- program output -----"
# Run the binary directly; it uses our musl loader.
/tmp/dhello
echo "--------------------------"
echo "Stage-2 dynamic smoke OK."
