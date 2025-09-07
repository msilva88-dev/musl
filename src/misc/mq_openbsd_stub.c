/* OpenBSD stage-1: POSIX mqueue stubs (no kernel SYS_mq_*).
 * All functions return -1 and set errno=ENOSYS, except mq_open which
 * returns (mqd_t)-1.  This is sufficient for static bootstrap.
 */
#include <mqueue.h>
#include <signal.h>
#include <time.h>
#include <errno.h>

int mq_close(mqd_t mqd)
{
	(void)mqd; errno = ENOSYS; return -1;
}

int mq_getattr(mqd_t mqd, struct mq_attr *attr)
{
	(void)mqd; (void)attr; errno = ENOSYS; return -1;
}

int mq_setattr(mqd_t mqd, const struct mq_attr *new, struct mq_attr *old)
{
	(void)mqd; (void)new; (void)old; errno = ENOSYS; return -1;
}

mqd_t mq_open(const char *name, int oflag, ...)
{
	(void)name; (void)oflag; errno = ENOSYS; return (mqd_t)-1;
}

int mq_unlink(const char *name)
{
	(void)name; errno = ENOSYS; return -1;
}

int mq_notify(mqd_t mqd, const struct sigevent *sev)
{
	(void)mqd; (void)sev; errno = ENOSYS; return -1;
}

ssize_t mq_receive(mqd_t mqd, char *msg_ptr, size_t msg_len, unsigned *prio)
{
	(void)mqd; (void)msg_ptr; (void)msg_len; (void)prio; errno = ENOSYS; return -1;
}

int mq_send(mqd_t mqd, const char *msg_ptr, size_t msg_len, unsigned prio)
{
	(void)mqd; (void)msg_ptr; (void)msg_len; (void)prio; errno = ENOSYS; return -1;
}

ssize_t mq_timedreceive(mqd_t mqd, char *msg_ptr, size_t msg_len,
                        unsigned *prio, const struct timespec *abstime)
{
	(void)mqd; (void)msg_ptr; (void)msg_len; (void)prio; (void)abstime; errno = ENOSYS; return -1;
}

int mq_timedsend(mqd_t mqd, const char *msg_ptr, size_t msg_len,
                 unsigned prio, const struct timespec *abstime)
{
	(void)mqd; (void)msg_ptr; (void)msg_len; (void)prio; (void)abstime; errno = ENOSYS; return -1;
}
