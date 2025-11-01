#define _BSD_SOURCE
#include <wchar.h>

size_t wcslcat(wchar_t *restrict d, const wchar_t *restrict s, size_t n)
{
	size_t dl = 0;
	const wchar_t *s1 = s;
	while (dl < n && *d) d++, dl++;
	size_t sp = (dl < n) ? n - dl - 1 : 0;
	while (sp && *s) sp--, *d++ = *s++;
	if (dl < n) *d = L'\0';
	while (*s1++);
	return dl + (size_t)(s1 - 1 - s);
}
