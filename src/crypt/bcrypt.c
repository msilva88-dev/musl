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

/* Encode 16-byte salt into 22-char bcrypt base64 (no padding).
 * Returns 0 on success, -1 on failure. */
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

/* Validate bcrypt version prefix in supplied salt:
 * Accept $2a$, $2b$, $2y$, returning 1 if valid, 0 otherwise. */
static int bcrypt_valid_version_prefix(const char *salt)
{
	if (!salt) return 0;
	/* Expect: $2x$ where x is a,b,y */
	if (salt[0] != '$' || salt[1] != '2') return 0;
	char v = salt[2];
	if (v != 'a' && v != 'b' && v != 'y') return 0;
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
