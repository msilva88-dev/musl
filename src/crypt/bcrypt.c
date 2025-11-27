/*
 * bcrypt wrappers for musl using existing crypt_blowfish integration.
 * This adapts OpenBSD 7.0 bcrypt interfaces without re-implementing Blowfish.
 *
 * - Relies on crypt(3) supporting $2a$/$2b$/$2y$ prefixes via src/crypt/crypt_blowfish.c.
 * - Provides bcrypt_newhash and bcrypt_checkpass similar to OpenBSD.
 * - Uses arc4random_buf (available via include/stdlib.h) for salt.
 */

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>   /* arc4random_buf */
#include <string.h>
#include <unistd.h>
#include <crypt.h>    /* crypt(3) prototype */

/* Bcrypt base64 alphabet (standard) */
static const char bcrypt_b64[] =
	"./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

/* Encode 16-byte salt into 22-char bcrypt base64 (no padding) */
static int bcrypt_base64_encode_16(const uint8_t in[16], char out[23])
{
	/* Bcrypt’s base64 encodes 128 bits -> 22 chars (no padding).
	 * This routine follows the encoding used by bcrypt (not standard MIME base64). */
	uint32_t v;
	int i = 0, o = 0;
	uint8_t buf[18];
	/* Pad with zeros to simplify looping over 3-byte chunks */
	memcpy(buf, in, 16);
	buf[16] = 0;
	buf[17] = 0;

	while (i < 18 && o < 22) {
		v = (uint32_t)buf[i] << 16;
		v |= (uint32_t)buf[i+1] << 8;
		v |= (uint32_t)buf[i+2];
		i += 3;

		out[o++] = bcrypt_b64[(v >> 18) & 0x3f];
		out[o++] = bcrypt_b64[(v >> 12) & 0x3f];
		out[o++] = bcrypt_b64[(v >> 6) & 0x3f];
		out[o++] = bcrypt_b64[v & 0x3f];
	}
	/* Truncate to 22 characters */
	if (o < 22) return -1;
	out[22] = '\0';
	return 0;
}

/* Build bcrypt salt string: $2b$CC$<22chars> */
static int bcrypt_make_salt_string(int log_rounds, const uint8_t salt16[16], char salt_out[30])
{
	if (log_rounds < 4 || log_rounds > 31) { errno = EINVAL; return -1; }
	char enc[23];
	if (bcrypt_base64_encode_16(salt16, enc) != 0) return -1;
	int n = snprintf(salt_out, 30, "$2b$%02d$%s", log_rounds, enc);
	return (n > 0 && n < 30) ? 0 : -1;
}

/* Generate a bcrypt hash into out buffer. outlen should be >= 61 bytes. */
int bcrypt_newhash(const char *pass, int log_rounds, char *out, size_t outlen)
{
	if (!pass || !out) { errno = EINVAL; return -1; }
	/* Typical bcrypt output length is 60 chars + NUL */
	if (outlen < 61) { errno = ENOSPC; return -1; }

	uint8_t salt16[16];
	arc4random_buf(salt16, 16);

	char saltstr[30];
	if (bcrypt_make_salt_string(log_rounds, salt16, saltstr) != 0) return -1;

	/* Delegate to musl’s crypt(), which routes to crypt_blowfish */
	char *res = crypt(pass, saltstr);
	if (!res) return -1;

	/* Copy result */
	size_t n = strnlen(res, outlen);
	if (n >= outlen) { errno = ENOSPC; return -1; }
	memcpy(out, res, n+1);
	return 0;
}

/* Verify password against bcrypt hash in constant time */
int bcrypt_checkpass(const char *pass, const char *hash)
{
	if (!pass || !hash) { errno = EINVAL; return -1; }
	/* crypt() with the stored hash as salt produces comparable output */
	char *res = crypt(pass, hash);
	if (!res) return -1;
	/* Constant-time compare */
	const unsigned char *a = (const unsigned char *)res;
	const unsigned char *b = (const unsigned char *)hash;
	size_t na = strlen(res), nb = strlen(hash);
	if (na != nb) return -1;
	unsigned diff = 0;
	for (size_t i = 0; i < na; i++) diff |= (unsigned)(a[i] ^ b[i]);
	return diff == 0 ? 0 : -1;
}

/* Optional: OpenBSD-like bcrypt_gensalt interface */
int bcrypt_gensalt(int log_rounds, char out[30])
{
	uint8_t salt16[16];
	arc4random_buf(salt16, 16);
	return bcrypt_make_salt_string(log_rounds, salt16, out);
}
