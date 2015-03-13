#ifndef _MIBENCH_HYBRID_H
	#define _MIBENCH_HYBRID_H

	#define MAX_HWT 14
	#define MAX_THREADS 32

	/*define slots*/
	#define NUSQRT_THREADS 12		/*number of hwt_usqrts instances	*/
	#define FIRST_USQRT_SLOT 0		/*first slot 0 => last lost 12		*/
	#define NSHORT_TERM_THREADS 1	/*number of hwt_short_term_synthesis_filtering instances*/
	#define FIRST_SHORT_TERM_SLOT 12/*hwt_short_term_synthesis_filtering gets slot 12*/
	#define NADPCM_THREADS 1		/*number of hwt_adpcm instances		*/
	#define FIRST_ADPCM_SLOT 13 	/*hwt_adpcm gets slot 13			*/


	#define TRUE 1
	#define FALSE 0
#endif
