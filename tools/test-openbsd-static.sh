#!/bin/sh
set -eu
tools/config-openbsd-x86_64
make clean libc.a
cat > /tmp/hello.c <<'EOF'
#include <unistd.h>
int main(void){ const char s[]="hello from musl/obsd\n"; write(1,s,sizeof s-1); return 0; }
EOF
${CC:-cc} -static -nostdlib -no-pie -o /tmp/hello /tmp/hello.c ./lib/libc.a
echo "Built /tmp/hello"
if command -v ktrace >/dev/null 2>&1; then
  ktrace -di /tmp/hello || true
  kdump | egrep 'execve|open|mmap|write|ENOENT' || true
fi
echo "Run /tmp/hello to verify output."
