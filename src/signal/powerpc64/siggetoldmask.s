.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	ld r3, 0(r2)
	blr
