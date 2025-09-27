.text
.globl __siggetoldmask
.hidden __siggetoldmask
.type __siggetoldmask, @function
__siggetoldmask:
	l %r2,0(%r13)
	br %r14
