	.global __restore
	.hidden __restore
	.type __restore,%function
__restore:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	li      0, 103 #__NR_sigreturn
#elif defined(__linux__)
	li      0, 119 #__NR_sigreturn
#endif
	sc

	.global __restore_rt
	.hidden __restore_rt
	.type __restore_rt,%function
__restore_rt:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	li      0, 103 # __NR_sigreturn
#elif defined(__linux__)
	li      0, 172 # __NR_rt_sigreturn
#endif
	sc
