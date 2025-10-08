	nop
.global __restore_rt
.hidden __restore_rt
.type __restore_rt,@function
__restore_rt:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	mov $103, %rax
#elif defined(__linux__)
	mov $15, %rax
#endif
	syscall
.size __restore_rt,.-__restore_rt
