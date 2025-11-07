#define _BSD_SOURCE
#include <stdarg.h>
#include <stddef.h>
#include <syslog.h>
#include "libc.h"
#include "lock.h"
#include "syscall.h"

int setlogmask_r(int mask, struct syslog_data *data)
{
	LOCK(lock);
	int ret = data->log_mask;
	if (mask) data->log_mask = mask;
	UNLOCK(lock);
	return ret;
}

void closelog_r(struct syslog_data *data)
{
	int cs;
	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
	LOCK(lock);
	data->log_tag = NULL;
	UNLOCK(lock);
	pthread_setcancelstate(cs, NULL);
}

void openlog_r(const char *ident, int opt, int facility, struct syslog_data *data)
{
	int cs;
	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
	LOCK(lock);
	if (ident) data->log_tag = ident;
	data->log_stat = opt;
	if (facility && !(facility &~ LOG_FACMASK)) data->log_fac = facility;
	UNLOCK(lock);
	pthread_setcancelstate(cs, NULL);
}

static inline void __dec(int *plen, int *tleft, char **taddr)
{
	if (*plen < 0) *plen = 0;
	if (*plen >= *tleft) *plen = *tleft - 1;
	*taddr = *taddr + *plen;
	*tleft = *tleft - *plen;
}

enum {
	__VSL_PMASK = LOG_PRIMASK | LOG_FACMASK,
	__VSL_ILOG = LOG_ERR | LOG_CONS | LOG_PERROR | LOG_PID,
	__VSL_MSIZE = 1025,
	__VSL_TSIZE = LOG_MAXLINE+1
};

hidden void __vsyslog_r(int priority, struct syslog_data *data, const char *message, va_list ap)
{
	char c = '\0', ebuf[NL_TEXTMAX] = "", mbuf[__VSL_MSIZE] = "", tbuf[__VSL_TSIZE] = "";
	char *mptr = mbuf, *tptr = tbuf, *sptr = NULL;
	int bak_errno = 0, mleft = __VSL_MSIZE, plen = 0, tcount = 0, tleft = __VSL_TSIZE;
	int cs, log_stat, log_mask, log_fac;
	char *log_tag;

	if (priority & ~(__VSL_PMASK)) {
		char buf[128];
		int n = snprintf(
			buf,
			sizeof(buf),
			"<%d>syslog_r: unknown priority: %x\n",
			LOG_ERR|LOG_CONS,
			priority
		);
		if (n > 0) {
			if (n > sizeof(buf)) n = sizeof(buf); // limitar al tamaño del buffer
			write(STDERR_FILENO, buf, n);
		}
		priority &= __VSL_PMASK;
	}

	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &cs);
	LOCK(lock);
	if (!data->log_tag) data->log_tag = __progname;
	log_tag = data->log_tag;
	log_stat = data->log_stat;
	log_mask = data->log_mask;
	log_fac  = data->log_fac;
	UNLOCK(lock);
	pthread_setcancelstate(cs, NULL);

	if (!(LOG_MASK(LOG_PRI(priority)) & log_mask)) return;
	bak_errno = errno;

	if (!(priority & LOG_FACMASK)) priority = priority | log_fac;

	plen = snprintf(tptr, tleft, "<%d>", priority);
	__dec(&plen, &tleft, &tptr);

	if (log_stat & LOG_PERROR) sptr = tptr;

	plen = snprintf(tptr, tleft, "%.*s", NAME_MAX, log_tag);
	__dec(&plen, &tleft, &tptr);

	if (log_stat & LOG_PID) {
		plen = snprintf(tptr, tleft, "[%ld]", (long)getpid());
		__dec(&plen, &tleft, &tptr);
	}

	for (char i = 0; i < 2; i++) {
		if (tleft > 1) {
			*tptr = ':';
			tptr++;
			tleft--;
		}
	}

	while(mleft > 1 && (c = *message)) {
		switch (c) {
		case '%':
			switch (message[1]) {
			case 'm':
				message++;
				strerror_r(bak_errno, ebuf, sizeof(ebuf));
				plen = snprintf(mptr, mleft, "%s", ebuf);
				if (plen < 0) plen = 0;
				else if (plen >= mleft) plen = mleft-1;
				mptr = mptr + plen;
				mleft = mleft - plen;
				break;
			case '%':
				if (mleft > 2) {
					message++;
					*mptr = '%';
					mptr++;
					*mptr = '%';
					mptr++;
					mleft = mleft - 2;
				} else {
					// the condition is not meet, continue to default case of "c"
					__attribute__((__fallthrough__));
				}
				break;
			}
			break;
		default:
			*mptr = c;
			mptr++;
			mleft--;
			break;
		}

		message++;
	}
	*mptr = '\0';

	plen = vsnprintf(tptr, tleft, mbuf, ap);
	__dec(&plen, &tleft, &tptr);

	for (tcount = tptr - tbuf; tcount > 0 && tptr[-1] == '\n'; tcount--) *(--tptr) = '\0';

	if (log_stat & LOG_PERROR) {
		int std_len = 0;
		if (tcount > (sptr - tbuf)) std_len = tcount - (sptr - tbuf);
		struct iovec iovec_str[] = {
			{ .iov_base = sptr, .iov_len = std_len },
			{ .iov_base = "\n", .iov_len = 1 }
		};
		writev(STDERR_FILENO, iovec_str, 2);
	}

	__syscall(SYS_sendsyslog, tbuf, tcount, log_stat & LOG_CONS);
}

void syslog_r(int priority, struct syslog_data *data, const char *message, ...)
{
        va_list ap;
        va_start(ap, message);
        vsyslog_r(priority, data, message, ap);
        va_end(ap);
}

weak_alias(__vsyslog_r, vsyslog_r);
