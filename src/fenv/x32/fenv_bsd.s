#define _BSD_SOURCE

.global feenableexcept
.type feenableexcept,@function
feenableexcept:
		# maintain exceptions in the sse mxcsr, clear x87 exceptions
	mov %edi, %eax
	and $0x3f, %eax
	mov %eax, %ecx
	stmxcsr %eax
	mov %eax, %edx
	mov %edx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	mov %edx, %ebx
	shl $7, %ecx
	not %ecx
	and %ecx, %ebx
	ldmxcsr %ebx
	ret

.global fedisableexcept
.type fedisableexcept,@function
fedisableexcept:
		# maintain exceptions in the sse mxcsr, clear x87 exceptions
	mov %edi, %eax
	and $0x3f, %eax
	mov %eax, %ecx
	stmxcsr %eax
	mov %eax, %edx
	mov %edx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	mov %edx, %ebx
	shl $7, %ecx
	or %ecx, %ebx
	ldmxcsr %ebx
	ret

.global fegetexcept
.type fegetexcept,@function
fegetexcept:
	stmxcsr %eax
	mov %eax, %edx
	shr $7, %edx
	not %edx
	and $0x3f, %edx
	mov %edx, %eax
	ret
