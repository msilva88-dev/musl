#include <sys/utsname.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include "syscall.h"

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static int __sysctl_uts(int slname, struct utsname *uts)
{
	int mib[] = {
		(slname == HW_MACHINE) ? CTL_KERN : CTL_HW,
		slname
	};
	void *ptr;
	size_t len;

	switch (slname) {
	case HW_MACHINE:
		len = sizeof(uts->machine);
		ptr = &uts->machine;
		break;
	case KERN_HOSTNAME:
		len = sizeof(uts->nodename);
		ptr = &uts->nodename;
		break;
	case KERN_OSRELEASE:
		len = sizeof(uts->release);
		ptr = &uts->release;
		break;
	case KERN_OSTYPE:
		len = sizeof(uts->sysname);
		ptr = &uts->sysname;
		break;
	case KERN_OSVERSION:
	case KERN_VERSION:
		len = sizeof(uts->version);
		ptr = &uts->version;
		break;
	default:
		return -1;
	}

	if (syscall(SYS_sysctl, mib, 2, ptr, &len, NULL, 0) != -1) return 0;
	else return -1;
}

static inline int __sysctl_uname(struct utsname *uts)
{
	int r = 0, slnames[] = { KERN_OSTYPE, KERN_HOSTNAME, KERN_OSRELEASE, KERN_OSVERSION, HW_MACHINE };

	for (size_t i = 0; i < sizeof(slnames)/sizeof(slnames[0]); i++) {
		r = __sysctl_uts(slnames[i], uts);
		if (slnames[i] == KERN_OSVERSION && r == -1) __sysctl_uts(KERN_VERSION, uts);
	}

	return r;
}
#endif

int uname(struct utsname *uts)
{
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	return __sysctl_uname(uts);
#elif defined(__linux__)
	return syscall(SYS_uname, uts);
#endif
}
