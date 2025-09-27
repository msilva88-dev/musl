.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	movl %fs:0x0, %eax
	ret
