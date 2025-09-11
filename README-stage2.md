# Stage-2 (shared musl) – Handoff to HyperbolaBSD

This repo now builds **musl’s shared libc** and the **loader alias**. On stock
OpenBSD the kernel *does not* exec a non-system interpreter, so binaries whose
`PT_INTERP` points to `ld-musl-*` won’t run (expected `Exec format error`).
Despite that, the Stage-2 artifacts are correct and ready to be exercised on
**HyperbolaBSD**, where musl will be the system loader.

---

## What’s built (artifacts)

- `lib/libc.so` — shared musl libc (no dependencies)
- `lib/ld-musl-$(ARCH).so.1 -> libc.so` — loader alias (musl’s ldso *is* libc)
- CRT startfiles: `lib/Scrt1.o`, `lib/crti.o`, `lib/crtn.o`

> Built and tested on OpenBSD/amd64 as a bootstrap host.

---

## Rebuild (on the bootstrap host)

```sh
gmake -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" lib/libc.so lib/Scrt1.o lib/crti.o lib/crtn.o
gmake ldso-symlink
