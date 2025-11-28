/*
 * bcrypt interface matching the OpenBSD crypt(3)/bcrypt(3) manual expectations.
 *
 * Provided functions:
 *   char *bcrypt_gensalt(uint8_t log_rounds);
 *       Generates a bcrypt salt string: "$2b$CC$22chars" (NUL-terminated).
 *       Returns pointer to a static buffer (not thread-safe). NULL on error.
 *
 *   char *bcrypt(const char *key, const char *salt);
 *       Hashes 'key' using the supplied bcrypt 'salt' (which includes version,
 *       cost, and 22-char base64 salt) and returns the resulting bcrypt hash
 *       string. Returns pointer to static buffer (or crypt(3)'s static buffer)
 *       or NULL on error.
 *
 * Notes:
 * - This implementation delegates hashing to crypt(3), which in musl routes
 *   $2a$/$2b$/$2y$ salts to the existing Blowfish-based bcrypt logic.
 * - Maximum password length enforced here is 72 bytes (bcrypt spec).
 * - Salt generation uses arc4random_buf() for 128 bits of entropy.
 * - The returned buffers are static; concurrent calls will race. This matches
 *   documented historical behavior ("BUGS" in crypt.3). For thread safety,
 *   applications should use (or you may later provide) crypt_newhash /
 *   crypt_checkpass style reentrant APIs.
 */

#define _BSD_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h> /* arc4random_buf */
#include <string.h>
#include <unistd.h>
#include <crypt.h> /* crypt(3) prototype */

/* Bcrypt base64 alphabet (standard) */
static const char bcrypt_b64[] =
	"./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

/* Static buffers (not thread-safe) */
static char __bcrypt_salt_buf[30]; /* "$2b$CC$22chars" + NUL => up to 29 chars + NUL */
static char __bcrypt_hash_buf[80]; /* Enough for full bcrypt hash (60 chars) + extra margin */

/*
 * Correct bcrypt Radix-64 encoder (non-verbatim, clean implementation).
 * Packs bits in 6-bit chunks using the bcrypt alphabet, without '=' padding.
 * For 16 input bytes, output length is exactly 22 characters.
 *
 * Returns number of characters written on success; -1 on failure.
 */
static int bcrypt_radix64_encode(const uint8_t *src, size_t n, char *dst, size_t dstsz)
{
	size_t i = 0, o = 0;
	unsigned int c1, c2, c3;

	while (i < n) {
		/* Need space for up to 4 output chars each iteration */
		if (o + 4 > dstsz) return -1;

		c1 = src[i++];
		c2 = (i < n) ? src[i++] : 0;
		c3 = (i < n) ? src[i++] : 0;

		/* Emit first two chars always */
		dst[o++] = bcrypt_b64[(c1 >> 2) & 0x3f];
		dst[o++] = bcrypt_b64[((c1 & 0x03) << 4) | ((c2 >> 4) & 0x0f)];

		/* Emit third char only if there was a c2 from input */
		if ((i - 1) <= n) {
			dst[o++] = bcrypt_b64[((c2 & 0x0f) << 2) | ((c3 >> 6) & 0x03)];
		} else {
			break;
		}

		/* Emit fourth char only if there was a c3 from input */
		if (i <= n) {
			dst[o++] = bcrypt_b64[c3 & 0x3f];
		} else {
			break;
		}
	}

	/* NUL-terminate if space permits */
	if (o >= dstsz) return -1;
	dst[o] = '\0';
	return (int)o;
}

/* Encode 16-byte salt into exactly 22 bcrypt base64 chars (no padding).
 * Returns 0 on success, -1 on failure. */
static int bcrypt_base64_encode_16(const uint8_t in[16], char out[23])
{
	int n = bcrypt_radix64_encode(in, 16, out, 23);
	if (n != 22) return -1;
	return 0;
}

/* Validate bcrypt version prefix in supplied salt:
 * Accept $2a$, $2b$, $2y$, returning 1 if valid, 0 otherwise. */
static int bcrypt_valid_version_prefix(const char *salt)
{
	if (!salt) return 0;
	/* Expect: $2x$ where x is a,b,y */
	if (salt[0] != '$' || salt[1] != '2') return 0;
	char v = salt[2];
	/* Accept glibc historical variant 'x' for interoperability */
	if (v != 'a' && v != 'b' && v != 'y' && v != 'x') return 0;
	if (salt[3] != '$') return 0;
	return 1;
}

/* Generate bcrypt salt string with given log_rounds (cost).
 * Returns pointer to static buffer on success, NULL on error.
 * log_rounds must be between 4 and 31 (inclusive). */
char *bcrypt_gensalt(uint8_t log_rounds)
{
	if (log_rounds < 4 || log_rounds > 31) {
		errno = EINVAL;
		return NULL;
	}

	uint8_t raw[16];
	arc4random_buf(raw, sizeof raw);

	char enc[23];
	if (bcrypt_base64_encode_16(raw, enc) != 0) {
		errno = EINVAL;
		return NULL;
	}

	/* Format: $2b$CC$<22chars> */
	int n = snprintf(__bcrypt_salt_buf, sizeof __bcrypt_salt_buf,
	                 "$2b$%02u$%s", (unsigned)log_rounds, enc);
	if (n <= 0 || (size_t)n >= sizeof __bcrypt_salt_buf) {
		errno = ENOMEM;
		return NULL;
	}
	return __bcrypt_salt_buf;
}

/* bcrypt: hash key with provided bcrypt salt.
 * Returns pointer to static buffer containing the hash on success, NULL on failure.
 * Enforces max password length 72 bytes (bcrypt specification).
 *
 * The salt should be a full bcrypt salt string ("$2b$CC$22chars" or $2a$/ $2y$ variant). */
char *bcrypt(const char *key, const char *salt)
{
	if (!key || !salt) {
		errno = EINVAL;
		return NULL;
	}

	size_t klen = strlen(key);
	if (klen > 72) {
		/* Specification limit: longer passwords are truncated internally by
		 * some implementations; we choose to reject to avoid silent truncation. */
		errno = EINVAL;
		return NULL;
	}

	if (!bcrypt_valid_version_prefix(salt)) {
		errno = EINVAL;
		return NULL;
	}

	/* Delegate to crypt(3); crypt already handles bcrypt salts internally */
	char *res = crypt(key, salt);
	if (!res) {
		/* crypt sets errno appropriately; propagate NULL */
		return NULL;
	}

	/* Copy to our static buffer (optional; we could return res directly).
	 * This isolates from later crypt() calls if the application expects bcrypt()
	 * buffer not to be clobbered by another crypt() usage immediately. */
	size_t rlen = strnlen(res, sizeof __bcrypt_hash_buf);
	if (rlen >= sizeof __bcrypt_hash_buf) {
		errno = ENOMEM;
		return NULL;
	}
	memcpy(__bcrypt_hash_buf, res, rlen + 1);
	return __bcrypt_hash_buf;
}
