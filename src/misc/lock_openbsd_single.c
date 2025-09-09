/* Single-thread placeholders; enough for ldso/libc bootstrapping. */
void __lock(volatile int *l)
{
	(void)l;
}

void __unlock(volatile int *l)
{
	(void)l;
}
