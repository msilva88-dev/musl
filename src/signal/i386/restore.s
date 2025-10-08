.global __restore
.hidden __restore
.type __restore,@function
__restore:
	popl %eax
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	movl $103, %eax
#elif defined(__linux__)
	movl $119, %eax
#endif
	int $0x80

.global __restore_rt
.hidden __restore_rt
.type __restore_rt,@function
__restore_rt:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	movl $103, %eax
#elif defined(__linux__)
	movl $173, %eax
#endif
	int $0x80
