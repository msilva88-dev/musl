#include <sys/time.h>
#include <sys/types.h>
#include <stdint.h>

#ifndef bool_t
#define bool_t int32_t
#endif

#ifndef enum_t
#define enum_t int32_t
#endif

#ifndef mem_alloc
#define mem_alloc(sz) malloc(sz)
#endif

#ifndef mem_free
#define mem_free(ptr, pad) free(ptr)
#endif
