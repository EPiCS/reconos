#include "timing.h"
#include "xmk.h"
#include "sys/timer.h"

unsigned int time_ms(){
	unsigned int ticks;
	ticks = sys_xget_clock_ticks();
	return  (ticks * (SYSTMR_INTERVAL / SYSTMR_CLK_FREQ_KHZ));
}
