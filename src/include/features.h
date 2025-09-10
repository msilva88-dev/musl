#ifndef FEATURES_H
#define FEATURES_H

#include "../../include/features.h"

#define weak __attribute__((__weak__))
#ifndef MUSL_NO_HIDDEN
#define hidden __attribute__((__visibility__("hidden")))
#endif
#define weak_alias(old, new) \
	extern __typeof(old) new __attribute__((__weak__, __alias__(#old)))

#endif
