#!/bin/sh
# Tiny OpenBSD stage-2 smoke: build libc.so and run a dynamic hello
set -eu

echo "[$0] building shared libc..."
${MAKE:-gmake} -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" lib/libc.so

echo "[$0] ensuring ldso alias..."
${MAKE:-gmake} ldso-symlink

# Ensure musl CRT objects exist (do not use system /usr/lib/crt*.o)
echo "[$0] ensuring musl CRT objects..."
${MAKE:-gmake} -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" \
  lib/Scrt1.o lib/crti.o lib/crtn.o
for f in lib/Scrt1.o lib/crti.o lib/crtn.o; do
  [ -f "$f" ] || { echo "missing $f (musl CRT not built)"; exit 1; }
done

# Determine expected loader name (strip any stray CRs)
arch="$( (uname -m 2>/dev/null || uname -p 2>/dev/null || echo unknown) | tr -d '\r' )"
case "$arch" in
  amd64|x86_64) ldname="ld-musl-x86_64.so.1" ;;
  *) echo "unsupported arch for this smoke: $arch" >&2; exit 1 ;;
esac

# Choose compiler
: "${CC:=cc}"

# Minimal dynamic hello using write(2)
cat >/tmp/dhello.c <<'EOF'
#include <unistd.h>
int main(void) {
    const char msg[] = "hello from musl (dynamic)\n";
    (void)write(1, msg, sizeof msg - 1);
    return 0;
}
EOF

echo "[$0] compiling /tmp/dhello (PIE, musl CRT, rpath, custom interp)..."
# Build object first
"$CC" -fPIE -c -o /tmp/dhello.o /tmp/dhello.c
# Link with musl CRT and no system startup files
"$CC" -nostdlib -pie -o /tmp/dhello \
  ./lib/Scrt1.o ./lib/crti.o \
  /tmp/dhello.o \
  -Wl,-rpath,"$PWD/lib" \
  -Wl,-dynamic-linker,"$PWD/lib/$ldname" \
  -Wl,--allow-shlib-undefined \
  -L./lib -lc \
  ./lib/crtn.o

echo "[$0] PT_INTERP for /tmp/dhello:"
if command -v readelf >/dev/null 2>&1; then
  readelf -lW /tmp/dhello | awk '
    /INTERP/ {show=1; lines=0}
    show && lines<3 {print; lines++}
  '
else
  echo "(readelf not found)"
fi

echo "----- run via musl loader explicitly -----"
env LD_LIBRARY_PATH="$PWD/lib" "./lib/$ldname" /tmp/dhello
echo "----- run directly (may be ignored by kernel) -----"
if /tmp/dhello >/dev/null 2>&1; then
  echo "(ran directly)"
else
  echo "(direct run did not succeed; expected on some OpenBSD setups)"
fi
echo "------------------------------------------"
echo "Stage-2 dynamic smoke finished."
