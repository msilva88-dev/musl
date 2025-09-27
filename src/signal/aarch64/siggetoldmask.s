.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	mrs x0, tpidr_el0
	ldr w0, [x0]
	ret
