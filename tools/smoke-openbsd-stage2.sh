#!/bin/sh
# Tiny OpenBSD stage-2 smoke: build libc.so and run a dynamic hello
# Usage:
#   sh tools/smoke-openbsd-stage2.sh
#   MUSL_USE_MUSL_LDSO=1 sh tools/smoke-openbsd-stage2.sh   # force musl ldso in PT_INTERP
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

# Quick diagnostic: does libc.so export __libc_start_main?
if command -v readelf >/dev/null 2>&1; then
  if ! readelf -Ws lib/libc.so | awk '$4=="FUNC" && $8=="__libc_start_main"{found=1} END{exit !found}'; then
    echo "[warn] libc.so does not export __libc_start_main; link may fail." >&2
  fi
fi

# Determine expected loader name (strip any stray CRs)
arch="$( (uname -m 2>/dev/null || uname -p 2>/dev/null || echo unknown) | tr -d '\r' )"
case "$arch" in
  amd64|x86_64) ldname="ld-musl-x86_64.so.1" ;;
  *) echo "unsupported arch for this smoke: $arch" >&2; exit 1 ;;
esac

# Choose which dynamic loader to embed in PT_INTERP
os="$(uname -s 2>/dev/null || echo unknown)"
use_musl_ldso="${MUSL_USE_MUSL_LDSO:-0}"
case "$os" in
  OpenBSD)
    if [ "$use_musl_ldso" = "1" ]; then
      interp="$PWD/lib/$ldname"
      echo "[$0] WARNING: forcing musl ldso as PT_INTERP on OpenBSD (may fail with ENOEXEC)."
    else
      interp="/usr/libexec/ld.so"
    fi
    ;;
  *)
    interp="$PWD/lib/$ldname"
    ;;
esac
echo "[$0] using dynamic loader: $interp"

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
# Link with musl CRT and no system startup files; link explicitly to our libc.so
"$CC" -nostdlib -pie -o /tmp/dhello \
  ./lib/Scrt1.o ./lib/crti.o \
  /tmp/dhello.o \
  -Wl,--no-as-needed \
  -Wl,-rpath,"$PWD/lib" \
  -Wl,-dynamic-linker,"$interp" \
  ./lib/libc.so \
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

echo "----- ldd (trace loader resolution) -----"
if command -v ldd >/dev/null 2>&1; then
  ldd /tmp/dhello || true
fi
echo "----- LD_TRACE_LOADED_OBJECTS=1 -----"
LD_TRACE_LOADED_OBJECTS=1 /tmp/dhello 2>/dev/null || true

echo "----- run directly (kernel uses PT_INTERP) -----"
set +e
env LD_LIBRARY_PATH="$PWD/lib" /tmp/dhello
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "(direct run OK)"
else
  echo "(direct run failed with rc=$rc)"
  if [ "$os" = "OpenBSD" ] && [ "$use_musl_ldso" = "1" ]; then
    echo "Note: OpenBSD does not exec non-system interpreters; failure is expected when forcing musl ldso."
  fi
fi

echo "----- try explicit musl loader -----"
# On OpenBSD this usually fails with ENOEXEC; treat as best-effort.
env LD_LIBRARY_PATH="$PWD/lib" "./lib/$ldname" /tmp/dhello || \
  echo "(explicit ldso invocation not supported on this platform)"

echo "--------------------------------------------------------------"
echo "Stage-2 dynamic smoke finished."
