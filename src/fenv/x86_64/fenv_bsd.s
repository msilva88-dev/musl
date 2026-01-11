#define _BSD_SOURCE

.global feenableexcept
.type feenableexcept,@function
feenableexcept:
		# maintain exceptions in the sse mxcsr, clear x87 exceptions
	push %rbx
	sub $4, %rsp
	mov %edi, %eax
	and $0x3f, %eax
	mov %eax, %ecx
	stmxcsr (%rsp)
	mov (%rsp), %edx
	mov %edx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	mov %edx, %ebx
	shl $7, %ecx
	not %ecx
	and %ecx, %ebx
	mov %ebx, (%rsp)
	ldmxcsr (%rsp)
	add $4, %rsp
	pop %rbx
	ret

.global fedisableexcept
.type fedisableexcept,@function
fedisableexcept:
		# maintain exceptions in the sse mxcsr, clear x87 exceptions
	push %rbx
	sub $4, %rsp
	mov %edi, %eax
	and $0x3f, %eax
	mov %eax, %ecx
	stmxcsr (%rsp)
	mov (%rsp), %edx
	mov %edx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	mov %edx, %ebx
	shl $7, %ecx
	or %ecx, %ebx
	mov %ebx, (%rsp)
	ldmxcsr (%rsp)
	add $4, %rsp
	pop %rbx
	ret

.global fegetexcept
.type fegetexcept,@function
fegetexcept:
	sub $4, %rsp
	stmxcsr (%rsp)
	mov (%rsp), %eax
	mov %eax, %edx
	shr $7, %edx
	not %edx
	and $0x3f, %edx
	mov %edx, %eax
	add $4, %rsp
	ret
