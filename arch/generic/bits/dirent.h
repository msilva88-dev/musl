#define _DIRENT_HAVE_D_RECLEN
#define _DIRENT_HAVE_D_OFF
#define _DIRENT_HAVE_D_TYPE

struct dirent {
	ino_t d_ino;
	off_t d_off;
	unsigned short d_reclen;
	unsigned char d_type;
#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
	uint8_t d_namlen;
	uint8_t __d_padding[4];
#endif
	char d_name[256];
};
