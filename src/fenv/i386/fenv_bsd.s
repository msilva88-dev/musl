#define _BSD_SOURCE

.global feenableexcept
.type feenableexcept,@function
feenableexcept:
	sub $4, %esp
	mov 4(%esp), %eax
	and $0x3f, %eax
	mov %eax, %ecx
	call 1f
1:	mov $1, %eax
	cpuid
	test $0x02000000, %edx
	jz 1f
		# SSE route
	stmxcsr 0(%esp)
	mov 0(%esp), %ebx
	mov %ebx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	shl $7, %ecx
	not %ecx
	and %ecx, %ebx
	mov %ebx, 0(%esp)
	ldmxcsr 0(%esp)
	jmp 2f
		# x87 route
1:	fnstcw 0(%esp)
	movw 0(%esp), %dx
	movzwl %dx, %eax
	not %eax
	and $0x3f, %eax
	andw $~0x3f, %dx
	orw %cx, %dx
	movw %dx, 0(%esp)
	fldcw 0(%esp)
2:	add $4, %esp
	ret

.global fedisableexcept
.type fedisableexcept,@function
fedisableexcept:
	sub $4, %esp
	mov 4(%esp), %eax
	and $0x3f, %eax
	mov %eax, %ecx
	call 1f
1:	mov $1, %eax
	cpuid
	test $0x02000000, %edx
	jz 1f
		# SSE route
	stmxcsr 0(%esp)
	mov 0(%esp), %ebx
	mov %ebx, %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	shl $7, %ecx
	or %ecx, %ebx
	mov %ebx, 0(%esp)
	ldmxcsr 0(%esp)
	jmp 2f
		# x87 route
1:	fnstcw 0(%esp)
	movw 0(%esp), %dx
	movzwl %dx, %eax
	not %eax
	and $0x3f, %eax
	orw %cx, %dx
	movw %dx, 0(%esp)
	fldcw 0(%esp)
2:	add $4, %esp
	ret

.global fegetexcept
.type fegetexcept,@function
fegetexcept:
	sub $4, %esp
	call 1f
1:	mov $1, %eax
	cpuid
	test $0x02000000, %edx
	jz 1f
		# SSE route
	stmxcsr 0(%esp)
	mov 0(%esp), %eax
	shr $7, %eax
	not %eax
	and $0x3f, %eax
	jmp 2f
1:	fnstcw 0(%esp)
	movw 0(%esp), %dx
	movzwl %dx, %eax
	not %eax
	and $0x3f, %eax
2:	add $4, %esp
	ret
