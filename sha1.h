

#ifndef _SHA1_H
#define _SHA1_H

#include <limits.h>

#define SHA1_BLOCK_SIZE  64
#define SHA1_DIGEST_SIZE 20

#if defined(__cplusplus)
extern "C"
{
#endif

/* define an unsigned 32-bit type */

#if UINT_MAX == 0xffffffff
  typedef   unsigned int     sha1_32t;
#elif ULONG_MAX == 0xffffffff
  typedef   unsigned long    sha1_32t;
#else
#error Please define sha1_32t as an unsigned 32 bit type in sha2.h
#endif

/* type to hold the SHA256 context  */

typedef struct
{   sha1_32t count[2];
    sha1_32t hash[5];
    sha1_32t wbuf[16];
} sha1_ctx;

void sha1_compile(sha1_ctx ctx[1]);

void sha1_begin(sha1_ctx ctx[1]);
void sha1_hash(const unsigned char data[], unsigned int len, sha1_ctx ctx[1]);
void sha1_end(unsigned char hval[], sha1_ctx ctx[1]);
void sha1(unsigned char hval[], const unsigned char data[], unsigned int len);

#if defined(__cplusplus)
}
#endif

#endif
