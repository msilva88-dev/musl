.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	ld a0, 0(tp)
	ret
