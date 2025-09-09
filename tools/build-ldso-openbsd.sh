#!/bin/sh
# Build musl's dynamic loader from the already-built objects.
# This is only for local smoke testing on OpenBSD during the port.
set -eu

CC=${CC:-cc}
TOP=${TOP:-$(dirname "$0")/..}
cd "$TOP"

OBJDLSTART=obj/ldso/dlstart.lo
OBJDYNLINK=obj/ldso/dynlink.lo
LIBDIR=./lib

case "$(uname -m)" in
  amd64|x86_64)  ARCH=x86_64 ;;
  *) echo "unsupported arch for this helper"; exit 1 ;;
esac

OUT_REAL=$LIBDIR/ld-musl-${ARCH}.so.1
OUT_OBSD=$LIBDIR/ld-musl-obsd-${ARCH}.so.1

# Only (re)link if the real loader file is missing.
if [ ! -f "$OUT_REAL" ]; then
  [ -f "$OBJDLSTART" ] && [ -f "$OBJDYNLINK" ] || {
    echo "ldso objects not found; build the tree first (gmake)" >&2
    exit 1
  }
  echo "[build-ldso] linking $OUT_REAL"
  # Entry is _dlstart; link as a shared object with no libc start files.
  "$CC" -shared -nostdlib -Wl,-e,_dlstart \
    -o "$OUT_REAL" "$OBJDLSTART" "$OBJDYNLINK" -L"$LIBDIR" -lc
fi

# Ensure the alias used by the smoke script exists.
if [ ! -f "$OUT_OBSD" ]; then
  ln -sf "$(basename "$OUT_REAL")" "$OUT_OBSD"
fi

echo "[build-ldso] ready: $OUT_REAL (alias $(basename "$OUT_OBSD"))"
