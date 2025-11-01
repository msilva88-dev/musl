#define _BSD_SOURCE
#include <wchar.h>

size_t wcslcpy(wchar_t *restrict d, const wchar_t *restrict s, size_t n)
{
	size_t a = (n) ? n - 1 : 0;
	const wchar_t *s1 = s;
	while (a && *s) a--, *d++ = *s++;
	if (n) *d = L'\0';
	while (*s1++);
	return (size_t)(s1 - 1 - s);
}
