	.global __restore
	.hidden __restore
	.type __restore,%function
__restore:
#if defined(__HyperbolaBSD__)
	svc 103 #__NR_sigreturn
#elif defined(__linux__)
	svc 119 #__NR_sigreturn
#endif

	.global __restore_rt
	.hidden __restore_rt
	.type __restore_rt,%function
__restore_rt:
#if defined(__HyperbolaBSD__)
	svc 103 # SYS_sigreturn
#elif defined(__linux__)
	svc 173 # __NR_rt_sigreturn
#endif
