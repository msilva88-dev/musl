#include <elf.h>
#include <link.h>
#if defined(__HyperbolaBSD__)
#include <hyperbk/sysctl.h>
#elif defined(__OpenBSD__)
#include <sys/sysctl.h>
#endif
#include "pthread_impl.h"
#include "libc.h"

#define AUX_CNT 38

extern weak hidden const size_t _DYNAMIC[];

#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
static char *execpath_bsd(void)
{
	char *argv0 = NULL, *argv0buf = NULL, *argvbuf = NULL, *buf = NULL;
	char *copy = NULL, *dir = NULL, *path_env = NULL, *saveptr = NULL;
	char *trypath = NULL;
	size_t argvlen = 0, trypathlen = 0;
	int mib_argv[4] = { CTL_KERN, KERN_PROC_ARGS, getpid(), KERN_PROC_ARGV };

	if (sysctl(mib_argv, 4, NULL, &argvlen, NULL, 0) == -1) return NULL;

	argvbuf = malloc(argvlen);
	if (!argvbuf) return NULL;

	if (sysctl(mib_argv, 4, argvbuf, &argvlen, NULL, 0) == -1) {
		free(argvbuf);
		return NULL;
	}

	argv0buf = ((char **)argvbuf)[0];
	if (!argv0buf) {
		free(argvbuf);
		return NULL;
	}

	argv0 = strdup(argv0buf);
	free(argvbuf);
	if (!argv0) return NULL;

	// argv0 contains '/', solve the absolute path
	if (strchr(argv0, '/')) {
		buf = realpath(argv0, NULL);
		free(argv0);
		if (!buf || strlen(buf) > PATH_MAX) {
			free(buf);
			return "";
		}
		return buf;
	}

	// argv0 no contains '/', search in PATH
	path_env = getenv("PATH");
	// Fallback path
	if (!path_env) path_env =
		"/bin:/sbin:/usr/bin:/usr/sbin:/usr/games:"
		"/usr/local/bin:/usr/local/sbin:/usr/local/games";

	copy = strdup(path_env);
	if (!copy) {
		free(argv0);
		return NULL;
	}

	dir = strtok_r(copy, ":", &saveptr);
	while (dir) {
		size_t needed = strlen(dir) + 1 + strlen(argv0) + 1;

		if (needed > trypathlen) {
			char *tmp = realloc(trypath, needed);
			if (!tmp) {
				free(trypath);
				free(copy);
				free(argv0);
				return NULL;
			}

			trypath = tmp;
			trypathlen = needed;
		}

		snprintf(trypath, trypathlen, "%s/%s", dir, argv0);
		if (access(trypath, X_OK) == 0) {
			buf = realpath(trypath, NULL);
			if (buf) {
				if (!buf || strlen(buf) > PATH_MAX) {
					free(buf);
					return NULL;
				}
				break;
			}
		}

		dir = strtok_r(NULL, ":", &saveptr);
	}

	free(trypath);
	free(copy);
	free(argv0);
	return buf;
}
#endif

static int static_dl_iterate_phdr(int(*callback)(struct dl_phdr_info *info, size_t size, void *data), void *data)
{
	unsigned char *p;
	ElfW(Phdr) *phdr, *tls_phdr=0;
	size_t base = 0;
	size_t n;
	struct dl_phdr_info info;
	size_t i, aux[AUX_CNT] = {0};

	for (i=0; libc.auxv[i]; i+=2)
		if (libc.auxv[i]<AUX_CNT) aux[libc.auxv[i]] = libc.auxv[i+1];

	for (p=(void *)aux[AT_PHDR],n=aux[AT_PHNUM]; n; n--,p+=aux[AT_PHENT]) {
		phdr = (void *)p;
		if (phdr->p_type == PT_PHDR)
			base = aux[AT_PHDR] - phdr->p_vaddr;
		if (phdr->p_type == PT_DYNAMIC && _DYNAMIC)
			base = (size_t)_DYNAMIC - phdr->p_vaddr;
		if (phdr->p_type == PT_TLS)
			tls_phdr = phdr;
	}
	info.dlpi_addr  = base;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	info.dlpi_name  = execpath_bsd();
#elif defined(__linux__)
	info.dlpi_name  = "/proc/self/exe";
#endif
	info.dlpi_phdr  = (void *)aux[AT_PHDR];
	info.dlpi_phnum = aux[AT_PHNUM];
	info.dlpi_adds  = 0;
	info.dlpi_subs  = 0;
	if (tls_phdr) {
		info.dlpi_tls_modid = 1;
		info.dlpi_tls_data = __tls_get_addr((tls_mod_off_t[]){1,0});
	} else {
		info.dlpi_tls_modid = 0;
		info.dlpi_tls_data = 0;
	}
	return (callback)(&info, sizeof (info), data);
}

weak_alias(static_dl_iterate_phdr, dl_iterate_phdr);
