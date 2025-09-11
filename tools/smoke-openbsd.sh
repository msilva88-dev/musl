#!/bin/sh
# Tiny OpenBSD static smoke test for the musl/obsd stage-1 build.
# - builds a minimal _start (mincrt) with an OpenBSD brand note
# - builds a tiny hello.c that calls write(2)
# - links statically against ./lib/libc.a
# - shows basic binary info and runs it
set -eu

: "${CC:=cc}"

BIN=/tmp/hello
ASM_MINCRT=/tmp/mincrt.S
OBJ_MINCRT=/tmp/mincrt.o
SRC_HELLO=/tmp/hello.c
OBJ_HELLO=/tmp/hello.o

rm -f "$BIN" "$OBJ_MINCRT" "$OBJ_HELLO" "$ASM_MINCRT" "$SRC_HELLO"

# Minimal _start and OpenBSD ELF brand note.
cat >"$ASM_MINCRT" <<'EOF'
        .text
        .globl  _start
        .type   _start,@function
_start:
        xor     %rbp, %rbp
        mov     (%rsp), %rdi
        lea     8(%rsp), %rsi
        lea     16(%rsp,%rdi,8), %rdx
        call    main
        mov     %rax, %rdi
        call    _exit
        .size   _start, . - _start

/* OpenBSD ELF brand note (ABI identification) */
        .section .note.openbsd.ident,"a"
        .p2align 2
        .long   8              /* namesz */
        .long   4              /* descsz */
        .long   1              /* type   */
        .asciz  "OpenBSD"
        .p2align 2
        .long   0              /* desc (0 = OpenBSD) */
        .text
EOF

# Hello that only uses write(2).
cat >"$SRC_HELLO" <<'EOF'
extern long write(int, const void*, unsigned long);

int main(void) {
    const char s[] = "hello from musl/obsd\n";
    write(1, s, sizeof s - 1);
    return 0;
}
EOF

echo "[1/3] assembling mincrt..."
"$CC" -c "$ASM_MINCRT" -o "$OBJ_MINCRT"

echo "[2/3] compiling hello.c..."
"$CC" -c "$SRC_HELLO" -o "$OBJ_HELLO"

echo "[3/3] linking static binary..."
"$CC" -static -nostdlib -nopie -Wl,-e,_start \
    -o "$BIN" "$OBJ_MINCRT" "$OBJ_HELLO" ./lib/libc.a

echo "Built $BIN"
echo "----- binary info -----"
command -v file   >/dev/null 2>&1 && file "$BIN" || true
command -v ldd    >/dev/null 2>&1 && ldd  "$BIN" || true
command -v readelf>/dev/null 2>&1 && readelf -h "$BIN" | sed -n '1,/:/p' || true

chmod +x "$BIN" || true
echo "----- program output -----"
if ! "$BIN"; then
    st=$?
    echo "program failed (exit $st): $BIN"
    echo "Hint: if the shell prints 'ELF: not found', try:"
    echo "  ktrace -di $BIN && kdump | egrep 'execve|ENOEXEC|EACCES' | tail -n 40"
    exit $st
fi

echo "--------------------------"
echo "Smoke test OK."
