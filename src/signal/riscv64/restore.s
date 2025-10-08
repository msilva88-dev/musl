.global __restore
.hidden __restore
.type __restore, %function
__restore:
.global __restore_rt
.hidden __restore_rt
.type __restore_rt, %function
__restore_rt:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	li a7, 103 # SYS_sigreturn
#elif defined(__linux__)
	li a7, 139 # SYS_rt_sigreturn
#endif
	ecall
