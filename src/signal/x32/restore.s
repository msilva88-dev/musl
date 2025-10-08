	nop
.global __restore_rt
.hidden __restore_rt
.type __restore_rt,@function
__restore_rt:
#if defined(__HyperbolaBSD__)
	mov $103, %rax /* SYS_sigreturn */
#elif defined(__linux__)
	mov $0x40000201, %rax /* SYS_rt_sigreturn */
#endif
	syscall
.size __restore_rt,.-__restore_rt
