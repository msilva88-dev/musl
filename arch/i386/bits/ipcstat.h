#if defined(__HyperbolaBSD__) || defined(__OpenBSD__)
#define IPC_STAT 2
#elif defined(__linux__)
#define IPC_STAT 0x102
#endif
