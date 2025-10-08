.global __restore_rt
.global __restore
.hidden __restore_rt
.hidden __restore
.type   __restore_rt,@function
.type   __restore,@function
__restore_rt:
__restore:
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	li.w	$a7, 103
#elif defined(__linux__)
	li.w    $a7, 139
#endif
	syscall 0
