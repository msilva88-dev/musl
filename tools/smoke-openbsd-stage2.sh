#!/bin/sh
# Tiny OpenBSD stage-2 smoke: build libc.so + ldso and run a dynamic hello
set -eu

echo "[$0] building shared libc and ldso..."
${MAKE:-gmake} -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" lib/libc.so
${MAKE:-gmake} -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" ldso/dynlink.lo

# Ensure we have the loader name musl expects
mkdir -p lib
arch="$(uname -m)"
case "$arch" in
  amd64|x86_64) ldname="ld-musl-x86_64.so.1" ;;
  *) echo "unsupported arch for this smoke: $arch" >&2; exit 1 ;;
esac
[ -e "lib/$ldname" ] || ln -sf libc.so "lib/$ldname"

cat > /tmp/dhello.c <<'C'
#include <unistd.h>
int main(){ const char s[]="hello (dynamic) from musl/obsd\n"; write(1,s,sizeof s-1); }
C
echo "[$0] linking dynamic hello against ./lib..."
cc -fPIC -o /tmp/dhello /tmp/dhello.c -Wl,-rpath,"$PWD/lib" -L./lib -lc

echo "----- program output -----"
LD_LIBRARY_PATH="$PWD/lib" ./lib/$ldname /tmp/dhello
echo "--------------------------"
echo "Stage-2 dynamic smoke OK."
