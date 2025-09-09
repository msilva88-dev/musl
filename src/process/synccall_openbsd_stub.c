/* Single-thread __synccall: just call the function on this thread. */
typedef void (*__synccall_fn)(void *);

int __synccall(__synccall_fn fn, void *arg)
{
	if (fn) fn(arg);
	return 0;
}
