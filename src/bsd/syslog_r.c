#define _BSD_SOURCE
#include <stdarg.h>
#include <stddef.h>
#include <syslog.h>

void closelog_r(struct syslog_data *data)
{
	data->log_tag = NULL;
}

void openlog_r(const char *ident, int opt, int facility, struct syslog_data *data)
{
	if (ident) data->log_tag = ident;
	data->log_stat = opt;
	if (facility && !(facility &~ LOG_FACMASK)) data->log_fac = logfac;
}

void syslog_r(int priority, struct syslog_data *data, const char *message, ...)
{
        va_list ap;
        va_start(ap, message);
        vsyslog_r(priority, data, message, ap);
        va_end(ap);
}
