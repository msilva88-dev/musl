.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	ld.w a0, 0(a4)
	ret
