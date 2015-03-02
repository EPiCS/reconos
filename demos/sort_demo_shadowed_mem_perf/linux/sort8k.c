#include "sort8k.h"
#include "bubblesort.h"
#include "reconos.h"
#include "mbox.h"
#include "config.h"
#include "timing.h"

#ifdef SHADOWING
	#include "thread_shadowing.h"
	#include "thread_shadowing_subs.h"
#endif

#include "mbox.h"
#include "rqueue.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

//#define BENCHMARK






