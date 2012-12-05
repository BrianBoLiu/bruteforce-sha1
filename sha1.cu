#include "macros.h"


__device__ void sha1_compile(sha1_ctx ctx[1])
{   


    sha1_32t    w[80], i, a, b, c, d, e, t;


    for(i = 0; i < SHA1_BLOCK_SIZE / 4; ++i)
        w[i] = swap_b32(ctx->wbuf[i]);

    for(i = SHA1_BLOCK_SIZE / 4; i < 80; ++i)
        w[i] = rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);

    a = ctx->hash[0];
    b = ctx->hash[1];
    c = ctx->hash[2];
    d = ctx->hash[3];
    e = ctx->hash[4];

    for(i = 0; i < 20; ++i)
    {
        rnd(ch, 0x5a827999);
    }

    for(i = 20; i < 40; ++i)
    {
        rnd(parity, 0x6ed9eba1);
    }

    for(i = 40; i < 60; ++i)
    {
        rnd(maj, 0x8f1bbcdc);
    }

    for(i = 60; i < 80; ++i)
    {
        rnd(parity, 0xca62c1d6);
    }

    ctx->hash[0] += a;
    ctx->hash[1] += b;
    ctx->hash[2] += c;
    ctx->hash[3] += d;
    ctx->hash[4] += e;
}

__device__ void sha1_begin(sha1_ctx ctx[1])
{
    ctx->count[0] = ctx->count[1] = 0;
    ctx->hash[0] = 0x67452301;
    ctx->hash[1] = 0xefcdab89;
    ctx->hash[2] = 0x98badcfe;
    ctx->hash[3] = 0x10325476;
    ctx->hash[4] = 0xc3d2e1f0;
}


__device__ void sha1_hash(const unsigned char data[],
                          unsigned int len, sha1_ctx ctx[1])
{   
    sha1_32t pos = (sha1_32t)(ctx->count[0] & SHA1_MASK),
             space = SHA1_BLOCK_SIZE - pos;
    const unsigned char *sp = data;

    if((ctx->count[0] += len) < len)
        ++(ctx->count[1]);

    while(len >= space)     /* tranfer whole blocks if possible  */
    {
        memcpy(((unsigned char*)ctx->wbuf) + pos, sp, space);
        sp += space; len -= space; space = SHA1_BLOCK_SIZE; pos = 0;
        sha1_compile(ctx);
    }



    memcpy(((unsigned char*)ctx->wbuf) + pos, sp, len);
}


__device__ void sha1_end(unsigned char hval[], sha1_ctx ctx[1])
{   sha1_32t    i = (sha1_32t)(ctx->count[0] & SHA1_MASK);


    ctx->wbuf[i >> 2] = (ctx->wbuf[i >> 2] & mask[i & 3]) | bits[i & 3];


    if(i > SHA1_BLOCK_SIZE - 9)
    {
        if(i < 60) ctx->wbuf[15] = 0;
        sha1_compile(ctx);
        i = 0;
    }
    else  
        i = (i >> 2) + 1;

    while(i < 14)
        ctx->wbuf[i++] = 0;


    ctx->wbuf[14] = swap_b32((ctx->count[1] << 3) | (ctx->count[0] >> 29));
    ctx->wbuf[15] = swap_b32(ctx->count[0] << 3);

    sha1_compile(ctx);

    for(i = 0; i < SHA1_DIGEST_SIZE; ++i)
        hval[i] = (unsigned char)(ctx->hash[i >> 2] >> (8 * (~i & 3)));
}

__device__ void sha1(unsigned char hval[], const unsigned char data[], unsigned int len)
{   
    sha1_ctx    cx[1];
    sha1_begin(cx); 
    sha1_hash(data, len, cx);
    sha1_end(hval, cx);
}
