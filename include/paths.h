#ifndef _PATHS_H
#define _PATHS_H

#define _PATH_DEFPATH "/usr/local/bin:/bin:/usr/bin"
#define _PATH_STDPATH "/bin:/usr/bin:/sbin:/usr/sbin"

#define _PATH_BSHELL	"/bin/sh"
#define _PATH_CONSOLE	"/dev/console"
#define _PATH_DEVNULL	"/dev/null"
#define _PATH_HEQUIV	"/etc/hosts.equiv"
#define _PATH_HOSTS	"/etc/hosts"
#define _PATH_LOG	"/dev/log"
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define _PATH_KLOG	"/dev/klog"
#elif defined(__linux__)
#define _PATH_KLOG	"/proc/kmsg"
#endif
#define _PATH_LASTLOG	"/var/log/lastlog"
#define _PATH_MAILDIR	"/var/mail"
#define _PATH_MAN	"/usr/share/man"
#define _PATH_MNTTAB	"/etc/fstab"
#define _PATH_FSTAB	_PATH_MNTTAB
#if defined(__OpenBSD__)
#define FSTAB		_PATH_MNTTAB
#endif
#define _PATH_NETWORKS	"/etc/networks"
#if defined(__linux__)
#define _PATH_MOUNTED	"/etc/mtab"
#endif
#define _PATH_NOLOGIN	"/etc/nologin"
#define _PATH_PROTOCOLS	"/etc/protocols"
#define _PATH_SENDMAIL	"/usr/sbin/sendmail"
#define _PATH_SERVICES	"/etc/services"
#define _PATH_SHADOW	"/etc/shadow"
#define _PATH_SHELLS	"/etc/shells"
#define _PATH_TTY	"/dev/tty"
#define _PATH_TTYS	"/etc/ttys"
#define _PATH_UTMP	"/dev/null/utmp"
#define _PATH_UUCPLOCK	"/var/spool/lock/"
#define _PATH_VI	"/usr/bin/vi"
#define _PATH_WTMP	"/dev/null/wtmp"

#define _PATH_DEV	"/dev/"
#define _PATH_TMP	"/tmp/"
#define _PATH_VARDB	"/var/lib/misc/"
#define _PATH_VARRUN	"/var/run/"
#define _PATH_VARTMP	"/var/tmp/"

#define _PATH_MASTERPASSWD "/etc/master.passwd"
#define _PATH_MASTERPASSWD_LOCK "/etc/ptmp"
#define _PATH_PWD_MKDB "/usr/sbin/pwd_mkdb"
#define _PATH_RSH "/usr/bin/ssh"

#endif
