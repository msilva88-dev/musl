#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _BSD_SOURCE
#include <sys/types.h>
#include <stddef.h>
#include <string.h>
#endif
#include <sys/utsname.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include "syscall.h"

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static int __sysctl_uts(int ctlname, int slname, struct utsname *uts)
{
	int mib[] = { ctlname, slname };
	void *ptr = NULL;
	size_t len = 0;

	switch (ctlname) {
	case CTL_HW:
		switch (slname) {
		case HW_MACHINE:
			len = sizeof(uts->machine);
			ptr = &uts->machine;
			break;
		default:
			return -1;
		}
		break;
	case CTL_KERN:
		switch (slname) {
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
		break;
	default:
		return -1;
	}

	if (syscall(SYS_sysctl, mib, 2, ptr, &len, NULL, 0) != -1) return 0;
	else return -1;
}

static inline int __sysctl_uname(struct utsname *uts)
{
	int r = 0;
	memset(uts, 0, sizeof *uts);

	const struct { int ctl, name; } mib[] = {
		{ CTL_KERN, KERN_OSTYPE },
		{ CTL_KERN, KERN_HOSTNAME },
		{ CTL_KERN, KERN_OSRELEASE },
		{ CTL_KERN, KERN_OSVERSION },
		{ CTL_HW, HW_MACHINE }
	};

	for (size_t i = 0; i < sizeof(mib)/sizeof(mib[0]); i++) {
		r = __sysctl_uts(mib[i].ctl, mib[i].name, uts);
		if (mib[i].ctl == CTL_KERN && mib[i].name == KERN_OSVERSION && r == -1) {
			r = __sysctl_uts(CTL_KERN, KERN_VERSION, uts);
		}
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
