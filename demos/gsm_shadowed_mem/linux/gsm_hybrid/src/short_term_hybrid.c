/*
 * short_term_hybrid.c
 *
 * Modified short_term.c for using in MiBenchHybrid
 *
 * Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
 * 
 * History:	08.03.2013 Alexander Sprenger created
 * 
 * */

/*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 */

/* $Header: /home/mguthaus/.cvsroot/mibench/telecomm/gsm/src/short_term.c,v 1.1.1.1 2000/11/06 19:54:26 mguthaus Exp $ */

#include <stdio.h>
#include <stdint.h>
#include <assert.h>

#include "private.h"

#include "gsm.h"
#include "proto.h"

/*RECONOS HEADERFILES*/
#include "reconos.h"
#include "rqueue.h"

#ifdef SHADOWING
#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"
#endif


/*TIMING */
#include "timing.h"


/* define/undefne dor additional output */
//#define GENERATE_TESTVECTORS
//#define _DEBUG
#define _MIBENCHOUTPUT
//#define _PRINT_TIMES

//Length of Reconosqueues
#define INDATA_LEN 5
#define OUTDATA_LEN 1

unsigned int rq_counter = 0;

/*
 *  SHORT TERM ANALYSIS FILTERING SECTION
 */

/* 4.2.8 */

static void Decoding_of_the_coded_Log_Area_Ratios P2((LARc,LARpp),
	word 	* LARc,		/* coded log area ratio	[0..7] 	IN	*/
	word	* LARpp)	/* out: decoded ..			*/
{
	register word	temp1 /* , temp2 */;
	register long	ltmp;	/* for GSM_ADD */

	/*  This procedure requires for efficient implementation
	 *  two tables.
 	 *
	 *  INVA[1..8] = integer( (32768 * 8) / real_A[1..8])
	 *  MIC[1..8]  = minimum value of the LARc[1..8]
	 */

	/*  Compute the LARpp[1..8]
	 */

	/* 	for (i = 1; i <= 8; i++, B++, MIC++, INVA++, LARc++, LARpp++) {
	 *
	 *		temp1  = GSM_ADD( *LARc, *MIC ) << 10;
	 *		temp2  = *B << 1;
	 *		temp1  = GSM_SUB( temp1, temp2 );
	 *
	 *		assert(*INVA != MIN_WORD);
	 *
	 *		temp1  = GSM_MULT_R( *INVA, temp1 );
	 *		*LARpp = GSM_ADD( temp1, temp1 );
	 *	}
	 */

#undef	STEP
#define	STEP( B, MIC, INVA )	\
		temp1    = GSM_ADD( *LARc++, MIC ) << 10;	\
		temp1    = GSM_SUB( temp1, B << 1 );		\
		temp1    = GSM_MULT_R( INVA, temp1 );		\
		*LARpp++ = GSM_ADD( temp1, temp1 );

	STEP(      0,  -32,  13107 );
	STEP(      0,  -32,  13107 );
	STEP(   2048,  -16,  13107 );
	STEP(  -2560,  -16,  13107 );

	STEP(     94,   -8,  19223 );
	STEP(  -1792,   -8,  17476 );
	STEP(   -341,   -4,  31454 );
	STEP(  -1144,   -4,  29708 );

	/* NOTE: the addition of *MIC is used to restore
	 * 	 the sign of *LARc.
	 */
}

/* 4.2.9 */
/* Computation of the quantized reflection coefficients 
 */

/* 4.2.9.1  Interpolation of the LARpp[1..8] to get the LARp[1..8]
 */

/*
 *  Within each frame of 160 analyzed speech samples the short term
 *  analysis and synthesis filters operate with four different sets of
 *  coefficients, derived from the previous set of decoded LARs(LARpp(j-1))
 *  and the actual set of decoded LARs (LARpp(j))
 *
 * (Initial value: LARpp(j-1)[1..8] = 0.)
 */

static void Coefficients_0_12 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int 	i;
	register longword ltmp;

	for (i = 1; i <= 8; i++, LARp++, LARpp_j_1++, LARpp_j++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 2 ), SASR( *LARpp_j, 2 ));
		*LARp = GSM_ADD( *LARp,  SASR( *LARpp_j_1, 1));
	}
}

static void Coefficients_13_26 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int i;
	register longword ltmp;
	for (i = 1; i <= 8; i++, LARpp_j_1++, LARpp_j++, LARp++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 1), SASR( *LARpp_j, 1 ));
	}
}

static void Coefficients_27_39 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int i;
	register longword ltmp;

	for (i = 1; i <= 8; i++, LARpp_j_1++, LARpp_j++, LARp++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 2 ), SASR( *LARpp_j, 2 ));
		*LARp = GSM_ADD( *LARp, SASR( *LARpp_j, 1 ));
	}
}


static void Coefficients_40_159 P2((LARpp_j, LARp),
	register word * LARpp_j,
	register word * LARp)
{
	register int i;

	for (i = 1; i <= 8; i++, LARp++, LARpp_j++)
		*LARp = *LARpp_j;
}

/* 4.2.9.2 */

static void LARp_to_rp P1((LARp),
	register word * LARp)	/* [0..7] IN/OUT  */
/*
 *  The input of this procedure is the interpolated LARp[0..7] array.
 *  The reflection coefficients, rp[i], are used in the analysis
 *  filter and in the synthesis filter.
 */
{
	register int 		i;
	register word		temp;
	register longword	ltmp;

	for (i = 1; i <= 8; i++, LARp++) {

		/* temp = GSM_ABS( *LARp );
	         *
		 * if (temp < 11059) temp <<= 1;
		 * else if (temp < 20070) temp += 11059;
		 * else temp = GSM_ADD( temp >> 2, 26112 );
		 *
		 * *LARp = *LARp < 0 ? -temp : temp;
		 */

		if (*LARp < 0) {
			temp = *LARp == MIN_WORD ? MAX_WORD : -(*LARp);
			*LARp = - ((temp < 11059) ? temp << 1
				: ((temp < 20070) ? temp + 11059
				:  GSM_ADD( temp >> 2, 26112 )));
		} else {
			temp  = *LARp;
			*LARp =    (temp < 11059) ? temp << 1
				: ((temp < 20070) ? temp + 11059
				:  GSM_ADD( temp >> 2, 26112 ));
		}
	}
}


/* 4.2.10 */
static void Short_term_analysis_filtering P4((S,rp,k_n,s),
	struct gsm_state * S,
	register word	* rp,	/* [0..7]	IN	*/
	register int 	k_n, 	/*   k_end - k_start	*/
	register word	* s	/* [0..n-1]	IN/OUT	*/
)
/*
 *  This procedure computes the short term residual signal d[..] to be fed
 *  to the RPE-LTP loop from the s[..] signal and from the local rp[..]
 *  array (quantized reflection coefficients).  As the call of this
 *  procedure can be done in many ways (see the interpolation of the LAR
 *  coefficient), it is assumed that the computation begins with index
 *  k_start (for arrays d[..] and s[..]) and stops with index k_end
 *  (k_start and k_end are defined in 4.2.9.1).  This procedure also
 *  needs to keep the array u[0..7] in memory for each call.
 */
{
	register word		* u = S->u;
	register int		i;
	register word		di, zzz, ui, sav, rpi;
	register longword 	ltmp;

	for (; k_n--; s++) {

		di = sav = *s;

		for (i = 0; i < 8; i++) {		/* YYY */

			ui    = u[i];
			rpi   = rp[i];
			u[i]  = sav;

			zzz   = GSM_MULT_R(rpi, di);
			sav   = GSM_ADD(   ui,  zzz);

			zzz   = GSM_MULT_R(rpi, ui);
			di    = GSM_ADD(   di,  zzz );
		}

		*s = di;
	}
}

#if defined(USE_FLOAT_MUL) && defined(FAST)

static void Fast_Short_term_analysis_filtering P4((S,rp,k_n,s),
	struct gsm_state * S,
	register word	* rp,	/* [0..7]	IN	*/
	register int 	k_n, 	/*   k_end - k_start	*/
	register word	* s	/* [0..n-1]	IN/OUT	*/
)
{
	register word		* u = S->u;
	register int		i;

	float 	  uf[8],
		 rpf[8];

	register float scalef = 3.0517578125e-5;
	register float		sav, di, temp;

	for (i = 0; i < 8; ++i) {
		uf[i]  = u[i];
		rpf[i] = rp[i] * scalef;
	}
	for (; k_n--; s++) {
		sav = di = *s;
		for (i = 0; i < 8; ++i) {
			register float rpfi = rpf[i];
			register float ufi  = uf[i];

			uf[i] = sav;
			temp  = rpfi * di + ufi;
			di   += rpfi * ufi;
			sav   = temp;
		}
		*s = di;
	}
	for (i = 0; i < 8; ++i) u[i] = uf[i];
}
#endif /* ! (defined (USE_FLOAT_MUL) && defined (FAST)) */

static void Short_term_synthesis_filtering P5((S,rrp,k,wt,sr),
	struct gsm_state * S,
	register word	* rrp,	/* [0..7]	IN	*/
	register int	k,	/* k_end - k_start	*/
	register word	* wt,	/* [0..k-1]	IN	*/
	register word	* sr	/* [0..k-1]	OUT	*/
)
{
	register word		* v = S->v;
	register int		i;
	register word		sri, tmp1, tmp2;
	register longword	ltmp;	/* for GSM_ADD  & GSM_SUB */
	
	#ifdef _DEBUG
	if(k==120)
		fprintf(stderr,"Software:\t\tS=%X, rrp=%X, k=%d,wt=%X, sr=%X\n", S, rrp, k, wt, sr);
	else
		fprintf(stderr,"Software:\t\tS=%X, rrp=%X, k=%d, wt=%X, sr=%X\n", S, rrp, k, wt, sr);
	#endif
	
	/* prints to generate input_testvectors */
	#ifdef GENERATE_TESTVECTORS
	int count_1,count_2 = 0;
	register word * wt_save;
	register word * sr_save;
	register int k_save;
	wt_save = wt;
	sr_save = sr;
	k_save = k;
	
	fprintf(stderr, "########PRE:STATUS\n");
	for(count_1=0;count_1<280;count_1++)
	{
		fprintf(stderr, "S->dp0[%d]=%d\n", count_1, S->dp0[count_1]);
	}
	fprintf(stderr, "S->z1=%d\n", S->z1);
	fprintf(stderr, "S->L_z2=%d\n", S->L_z2);
	fprintf(stderr, "S->mp=%d\n", S->mp);
	for(count_1=0;count_1<8;count_1++)
	{
		fprintf(stderr, "S->u[%d]=%d\n", count_1, S->u[count_1]);
	}
	for(count_1=0;count_1<2;count_1++)
	{
		for(count_2=0;count_2<8;count_2++)
		{
			fprintf(stderr, "S->LARpp[%d][%d]=%d\n", count_1, count_2, S->LARpp[count_1][count_2]);
		}
	}
	fprintf(stderr, "S->j=%d\n", S->j);
	fprintf(stderr, "S->nrp=%d\n", S->nrp);
	for(count_1=0;count_1<9;count_1++)
	{
		fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
	}
	fprintf(stderr, "S->msr=%d\n", S->msr);
	fprintf(stderr, "S->verbose=%d\n", S->verbose);
	fprintf(stderr, "S->fast=%d\n", S->fast);
	for(count_1=0;count_1<8;count_1++)
	{
		fprintf(stderr, "rrp[%d]=%d\n",count_1,rrp[count_1]);
	}
	fprintf(stderr, "k=%d\n", k_save);
	for(count_1=0;count_1<k_save;count_1++)
	{
		fprintf(stderr, "wt[%d]=%d\n",count_1,wt_save[count_1]);
	}
	for(count_1=0;count_1<k_save;count_1++)
	{
		fprintf(stderr, "sr[%d]=%d\n",count_1,sr_save[count_1]);
	}	
	#endif /* GENERATE_TESTVECTORS */

	while (k--) {
		sri = *wt++;
		for (i = 8; i--;) {

			/* sri = GSM_SUB( sri, gsm_mult_r( rrp[i], v[i] ) );
			 */
			tmp1 = rrp[i];
			tmp2 = v[i];
			tmp2 =  ( tmp1 == MIN_WORD && tmp2 == MIN_WORD
				? MAX_WORD
				: 0x0FFFF & (( (longword)tmp1 * (longword)tmp2
					     + 16384) >> 15)) ;

			sri  = GSM_SUB( sri, tmp2 );

			/* v[i+1] = GSM_ADD( v[i], gsm_mult_r( rrp[i], sri ) );
			 */
			tmp1  = ( tmp1 == MIN_WORD && sri == MIN_WORD
				? MAX_WORD
				: 0x0FFFF & (( (longword)tmp1 * (longword)sri
					     + 16384) >> 15)) ;

			v[i+1] = GSM_ADD( v[i], tmp1);
		}
		*sr++ = v[0] = sri;
	}
	
	/* prints to generate output_testvectors */
	#ifdef GENERATE_TESTVECTORS
	fprintf(stderr, "########POST:STATUS\n");
	for(count_1=0;count_1<280;count_1++)
	{
		fprintf(stderr, "S->dp0[%d]=%d\n", count_1, S->dp0[count_1]);
	}
	fprintf(stderr, "S->z1=%d\n", S->z1);
	fprintf(stderr, "S->L_z2=%d\n", S->L_z2);
	fprintf(stderr, "S->mp=%d\n", S->mp);
	for(count_1=0;count_1<8;count_1++)
	{
		fprintf(stderr, "S->u[%d]=%d\n", count_1, S->u[count_1]);
	}
	for(count_1=0;count_1<2;count_1++)
	{
		for(count_2=0;count_2<8;count_2++)
		{
			fprintf(stderr, "S->LARpp[%d][%d]=%d\n", count_1, count_2, S->LARpp[count_1][count_2]);
		}
	}
	fprintf(stderr, "S->j=%d\n", S->j);
	fprintf(stderr, "S->nrp=%d\n", S->nrp);
	for(count_1=0;count_1<9;count_1++)
	{
		fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
	}
	fprintf(stderr, "S->msr=%d\n", S->msr);
	fprintf(stderr, "S->verbose=%d\n", S->verbose);
	fprintf(stderr, "S->fast=%d\n", S->fast);
	for(count_1=0;count_1<8;count_1++)
	{
		fprintf(stderr, "rrp[%d]=%d\n",count_1,rrp[count_1]);
	}
	fprintf(stderr, "k=%d\n", k_save);
	for(count_1=0;count_1<k_save;count_1++)
	{
		fprintf(stderr, "wt[%d]=%d\n",count_1,wt_save[count_1]);
	}
	for(count_1=0;count_1<k_save;count_1++)
	{
		fprintf(stderr, "sr[%d]=%d\n",count_1,sr_save[count_1]);
	}
	#endif /* GENERATE_TESTVECTORS */
}

/*Softwarethread short_term_synthesis_filtering */
void *short_term_synthesis_filtering_swt(void* data)
{
		uint32 indata[INDATA_LEN];
		uint32 outdata[OUTDATA_LEN];
		
		struct reconos_resource *res  = (struct reconos_resource*) data;
		
		rqueue *rq_start = res[0].ptr;
		rqueue *rq_stop  = res[1].ptr;
				
		struct gsm_state	*S;	//pointer to the gsm_state struct
		word	*rrp;	//pointer to the first position of the rrp array
		int 	k;		// k_end - k_start
		word	*wt;	//pointer to the first position of the wt array
		word	*sr;	//pointer to the first position of the sr array
		
		int val;
		
		//pthread_t self = pthread_self();
		//printf("SW Thread %lu: running\n", self);
		
		while(1)
		{
			//recieve incoming reconosqueue
			val = rq_receive(rq_start, indata, INDATA_LEN*sizeof(uint32)); 
			if (indata[0] == UINT32_MAX)
			{
				//printf("SW Thread %lu: Got exit command from mailbox %p.\n", self, mb_start);
				pthread_exit((void*)0);
			}
			else
			{
				//get values from reconosqueue
				S	= (struct gsm_state *) 	indata[0];
				rrp	= (word *)	indata[1];
				k	= (int)		indata[2];
				wt	= (word *)	indata[3];
				sr	= (word *)	indata[4];
				
				#ifdef _DEBUG
				if(k==120)
					fprintf(stderr,"Softwarethread:\tS=%X, rrp=%X, k=%d,wt=%X, sr=%X, S->v=%X\n", S, rrp, k, wt, sr, S->v);
				else
					fprintf(stderr,"Softwarethread:\tS=%X, rrp=%X, k=%d, wt=%X, sr=%X, S->v=%X\n", S, rrp, k, wt, sr, S->v);
				#endif				
				
				//run Short_term_synthesis_filtering
				Short_term_synthesis_filtering( S, rrp, k, wt, sr);
			}
			
			//send reconosqueue for acknowledge 
			outdata[0] = (uint32) S;
			rq_send(rq_stop, outdata, OUTDATA_LEN*sizeof(uint32));
		}
}


#if defined(FAST) && defined(USE_FLOAT_MUL)

static void Fast_Short_term_synthesis_filtering P5((S,rrp,k,wt,sr),
	struct gsm_state * S,
	register word	* rrp,	/* [0..7]	IN	*/
	register int	k,	/* k_end - k_start	*/
	register word	* wt,	/* [0..k-1]	IN	*/
	register word	* sr	/* [0..k-1]	OUT	*/
)
{
	register word		* v = S->v;
	register int		i;

	float va[9], rrpa[8];
	register float scalef = 3.0517578125e-5, temp;

	for (i = 0; i < 8; ++i) {
		va[i]   = v[i];
		rrpa[i] = (float)rrp[i] * scalef;
	}
	while (k--) {
		register float sri = *wt++;
		for (i = 8; i--;) {
			sri -= rrpa[i] * va[i];
			if     (sri < -32768.) sri = -32768.;
			else if (sri > 32767.) sri =  32767.;

			temp = va[i] + rrpa[i] * sri;
			if     (temp < -32768.) temp = -32768.;
			else if (temp > 32767.) temp =  32767.;
			va[i+1] = temp;
		}
		*sr++ = va[0] = sri;
	}
	for (i = 0; i < 9; ++i) v[i] = va[i];
}

#endif /* defined(FAST) && defined(USE_FLOAT_MUL) */

void Gsm_Short_Term_Analysis_Filter P3((S,LARc,s),

	struct gsm_state * S,

	word	* LARc,		/* coded log area ratio [0..7]  IN	*/
	word	* s		/* signal [0..159]		IN/OUT	*/
)
{
	word		* LARpp_j	= S->LARpp[ S->j      ];
	word		* LARpp_j_1	= S->LARpp[ S->j ^= 1 ];

	word		LARp[8];

#undef	FILTER
#if 	defined(FAST) && defined(USE_FLOAT_MUL)
# 	define	FILTER 	(* (S->fast			\
			   ? Fast_Short_term_analysis_filtering	\
		    	   : Short_term_analysis_filtering	))

#else
# 	define	FILTER	Short_term_analysis_filtering
#endif

	Decoding_of_the_coded_Log_Area_Ratios( LARc, LARpp_j );

	Coefficients_0_12(  LARpp_j_1, LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, s);

	Coefficients_13_26( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 14, s + 13);

	Coefficients_27_39( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, s + 27);

	Coefficients_40_159( LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 120, s + 40);
}

void Gsm_Short_Term_Synthesis_Filter P4((S, LARcr, wt, s),
	struct gsm_state * S,

	word	* LARcr,	/* received log area ratios [0..7] IN  */
	word	* wt,		/* received d [0..159]		   IN  */

	word	* s		/* signal   s [0..159]		  OUT  */
)
{
	word		* LARpp_j	= S->LARpp[ S->j     ];
	word		* LARpp_j_1	= S->LARpp[ S->j ^=1 ];

	word		LARp[8];

#undef	FILTER
#if 	defined(FAST) && defined(USE_FLOAT_MUL)

# 	define	FILTER 	(* (S->fast			\
			   ? Fast_Short_term_synthesis_filtering	\
		    	   : Short_term_synthesis_filtering	))
#else
#	define	FILTER	Short_term_synthesis_filtering
#endif

	Decoding_of_the_coded_Log_Area_Ratios( LARcr, LARpp_j );

	Coefficients_0_12( LARpp_j_1, LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, wt, s );

	Coefficients_13_26( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 14, wt + 13, s + 13 );

	Coefficients_27_39( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, wt + 27, s + 27 );

	Coefficients_40_159( LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER(S, LARp, 120, wt + 40, s + 40);
}

/* 
 * MiBenchHybrid Gsm_Short_Term_Sythesis_Filter_hybrid
 * modified Gsm_Short_Term_Synthesos_Filter with reconosqueue sends and receives
 * */
void Gsm_Short_Term_Synthesis_Filter_hybrid P6((S, LARcr, wt, s, rq_sending, rq_receiving),
	struct gsm_state * S,

	word	* LARcr,	/* received log area ratios [0..7] IN  */
	word	* wt,		/* received d [0..159]		   IN  */

	word	* s,		/* signal   s [0..159]		  OUT  */
	rqueue	* rq_sending,	/* rq_sending address */
	rqueue	* rq_receiving/* rq_receiving address */
)
{
	word		* LARpp_j	= S->LARpp[ S->j     ];
	word		* LARpp_j_1	= S->LARpp[ S->j ^=1 ];

	word		LARp[8];
	
	//temp arrays for memory management
	int i = 0;
	//this arrays have to beginn at the start of a wordadress
	word wt_temp[120];
	word s_temp[120];
	
	//timing variables
	timing_t t_start, t_stop;
	ms_t t_coefficients = 0;
	ms_t t_short_term_filtering = 0;
	
	int ret = 0;
	
	uint32 indata[INDATA_LEN];
	uint32 outdata[OUTDATA_LEN];
	
	//for debug/generatetestvectors
	int count_1 , count_2;

#undef	FILTER
#if 	defined(FAST) && defined(USE_FLOAT_MUL)

# 	define	FILTER 	(* (S->fast			\
			   ? Fast_Short_term_synthesis_filtering	\
		    	   : Short_term_synthesis_filtering))
#else
#	define	FILTER	Short_term_synthesis_filtering
#endif

	Decoding_of_the_coded_Log_Area_Ratios( LARcr, LARpp_j );
	
	#ifdef _DEBUG
		fprintf(stderr, "########PRE AUSFUEHRUNG GSM_SHORT_TERM_1\n");
		fprintf(stderr, "wt_temp=%X\ts_temp=%X\n", wt_temp, s_temp);
		fprintf(stderr, ((int)wt_temp % 4==0 && (int)s_temp % 4==0) ? "OK\n" : "WARNING\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	t_start = gettime();	
	Coefficients_0_12( LARpp_j_1, LARpp_j, LARp );
	LARp_to_rp( LARp );	
	t_stop = gettime();
	t_coefficients += calc_timediff_ms(t_start,t_stop);
	
	t_start = gettime();
	//FILTER( S, LARp, 13, wt, s );
	//build and send reconosqueue message
	indata[0] = (uint32) S;
	indata[1] = (uint32) LARp;
	indata[2] = (uint32) 13;
	
	/* copy values to temp array if array starts at wrong position else use original values */
	if( (int)wt % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			wt_temp[i]=wt[i];
		}
		indata[3] = (uint32) wt_temp;
	}
	else
	{
		indata[3] = (uint32) wt;
	}
	if( (int)s % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			s_temp[i]=s[i];
		}
		indata[4] = (uint32) s_temp;
	}
	else
	{
		indata[4] = (uint32) s;
	}
	/* END: copy values to temp array if array starts at wrong position else use original values */
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "PRE re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	#endif
	fprintf(stderr,"%d rq_send(0x%x,0x%x,%d)\n", rq_counter++, rq_sending,indata,INDATA_LEN*sizeof(uint32));
	rq_send(rq_sending, indata, INDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	
	fprintf(stderr, "PRE re_receive: outdata(%X)\n", outdata[0]);
	#endif
	//fprintf(stderr,"%d rq_receive(0x%x,0x%x,%d)\n", rq_counter++, rq_receiving,outdata,OUTDATA_LEN*sizeof(uint32));
	ret = rq_receive(rq_receiving, outdata, OUTDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_receive: outdata(%X)\n", outdata[0]);
	#endif
	if(ret == -1)
	{
		fprintf(stderr, "ERROR: rq_recieve bigger than expected!\n");
		exit(1);
	}
	
	/* copy changed tempvalues in original array */
	if( (int)wt % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			wt[i]=wt_temp[i];
		}
	}
	if( (int)s % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			s[i]=s_temp[i];
		}
	}
	/* END: copy changed temp values in original array */
	t_stop = gettime();
	t_short_term_filtering += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########POST AUSFUEHRUNG GSM_SHORT_TERM_1\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	
	t_start = gettime();
	Coefficients_13_26( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	t_stop = gettime();
	t_coefficients += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########PRE AUSFUEHRUNG GSM_SHORT_TERM_2\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	t_start = gettime();
	//FILTER( S, LARp, 14, wt + 13, s + 13 );
	//build and send reconosqueue message
	indata[0] = (uint32) S;
	indata[1] = (uint32) LARp;
	indata[2] = (uint32) 14;
	
	/* copy values to temp array if array starts at wrong position else use original values */
	if( (int)(wt+13) % 4 != 0)
	{
		for(i=0;i<14;i++)
		{
			wt_temp[i]=wt[i+13];
		}
		indata[3] = (uint32) wt_temp;
	}
	else
	{
		indata[3] = (uint32) (wt+13);
	}
	if( (int)(s+13) % 4 != 0)
	{
		for(i=0;i<14;i++)
		{
			s_temp[i]=s[i+13];
		}
		indata[4] = (uint32) s_temp;
	}
	else
	{
		indata[4] = (uint32) (s+13);
	}
	/* END: copy values to temp array if array starts at wrong position else use original values */
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "PRE re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	#endif
	fprintf(stderr,"%d rq_send(0x%x,0x%x,%d)\n", rq_counter++, rq_sending,indata,INDATA_LEN*sizeof(uint32));
	rq_send(rq_sending, indata, INDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	
	fprintf(stderr, "PRE re_receive: outdata(%X)\n", outdata[0]);
	#endif
	//fprintf(stderr,"%d rq_receive(0x%x,0x%x,%d)\n", rq_counter++, rq_receiving,outdata,OUTDATA_LEN*sizeof(uint32));
	ret = rq_receive(rq_receiving, outdata, OUTDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_receive: outdata(%X)\n", outdata[0]);
	#endif
	
	/* copy changed tempvalues in original array */
	if(ret == -1)
	{
		fprintf(stderr, "ERROR: rq_recieve bigger than expected!\n");
		exit(1);
	}
	if( (int)(wt+13) % 4 != 0)
	{
		for(i=0;i<14;i++)
		{
			wt[i+13]=wt_temp[i];
		}
	}
	if( (int)(s+13) % 4 != 0)
	{
		for(i=0;i<14;i++)
		{
			s[i+13]=s_temp[i];
		}
	}
	/* END: copy changed temp values in original array */
	
	t_stop = gettime();
	t_short_term_filtering += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########POST AUSFUEHRUNG GSM_SHORT_TERM_2\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	
	t_start = gettime();
	Coefficients_27_39( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	t_stop = gettime();
	t_coefficients += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########PRE AUSFUEHRUNG GSM_SHORT_TERM_3\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	t_start = gettime();
	//FILTER( S, LARp, 13, wt + 27, s + 27 );
	//build and send reconosqueue message
	indata[0] = (uint32) S;
	indata[1] = (uint32) LARp;
	indata[2] = (uint32) 13;
	
	/* copy values to temp array if array starts at wrong position else use original values */
	if( (int)(wt+27) % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			wt_temp[i]=wt[i+27];
		}
		indata[3] = (uint32) wt_temp;
	}
	else
	{
		indata[3] = (uint32) (wt+27);
	}
	if( (int)(s+27) % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			s_temp[i]=s[i+27];
		}
		indata[4] = (uint32) s_temp;
	}
	else
	{
		indata[4] = (uint32) (s+27);
	}
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "PRE re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	#endif
	fprintf(stderr,"%d rq_send(0x%x,0x%x,%d)\n", rq_counter++, rq_sending,indata,INDATA_LEN*sizeof(uint32));
	rq_send(rq_sending, indata, INDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	
	fprintf(stderr, "PRE re_receive: outdata(%X)\n", outdata[0]);
	#endif
	//fprintf(stderr,"%d rq_receive(0x%x,0x%x,%d)\n", rq_counter++, rq_receiving,outdata,OUTDATA_LEN*sizeof(uint32));
	ret = rq_receive(rq_receiving, outdata, OUTDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_receive: outdata(%X)\n", outdata[0]);
	#endif
	if(ret == -1)
	{
		fprintf(stderr, "ERROR: rq_recieve bigger than expected!\n");
		exit(1);
	}
	
	/* copy changed tempvalues in original array */
	if( (int)(wt+27) % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			wt[i+27]=wt_temp[i];
		}
	}
	if( (int)(s+27) % 4 != 0)
	{
		for(i=0;i<13;i++)
		{
			s[i+27]=s_temp[i];
		}
	}
	/* END: copy changed temp values in original array */
	
	t_stop = gettime();
	t_short_term_filtering += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########POST AUSFUEHRUNG GSM_SHORT_TERM_3\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	
	t_start = gettime();
	Coefficients_40_159( LARpp_j, LARp );
	LARp_to_rp( LARp );
	t_stop = gettime();
	t_coefficients += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########PRE AUSFUEHRUNG GSM_SHORT_TERM_4\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	t_start = gettime();
	//FILTER(S, LARp, 120, wt + 40, s + 40);
	//build and send reconosqueue message
	indata[0] = (uint32) S;
	indata[1] = (uint32) LARp;
	indata[2] = (uint32) 120;
	
	/* copy values to temp array if array starts at wrong position else use original values */
	if( (int)(wt+40) % 4 != 0)
	{
		for(i=0;i<120;i++)
		{
			wt_temp[i]=wt[i+40];
		}
		indata[3] = (uint32) wt_temp;
	}
	else
	{
		indata[3] = (uint32) (wt+40);
	}
	if( (int)(s+40) % 4 != 0)
	{
		for(i=0;i<120;i++)
		{
			s_temp[i]=s[i+40];
		}
		indata[4] = (uint32) s_temp;
	}
	else
	{
		indata[4] = (uint32) (s+40);
	}
	/* END: copy values to temp array if array starts at wrong position else use original values */
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "PRE re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	#endif
	fprintf(stderr,"%d rq_send(0x%x,0x%x,%d)\n", rq_counter++, rq_sending,indata,INDATA_LEN*sizeof(uint32));
	rq_send(rq_sending, indata, INDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_send: indata(%X, %X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3], indata[4]);
	
	fprintf(stderr, "PRE re_receive: outdata(%X)\n", outdata[0]);
	#endif
	//fprintf(stderr,"%d rq_receive(0x%x,0x%x,%d)\n", rq_counter++, rq_receiving,outdata,OUTDATA_LEN*sizeof(uint32));
	ret = rq_receive(rq_receiving, outdata, OUTDATA_LEN*sizeof(uint32));
	
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "POST re_receive: outdata(%X)\n", outdata[0]);
	#endif
	if(ret == -1)
	{
		fprintf(stderr, "ERROR: rq_recieve bigger than expected!\n");
		exit(1);
	}
	
	/* copy changed tempvalues in original array */
	if( (int)(wt+40) % 4 != 0)
	{
		for(i=0;i<120;i++)
		{
			wt[i+40]=wt_temp[i];
		}
	}
	if( (int)(s+40) % 4 != 0)
	{
		for(i=0;i<120;i++)
		{
			s[i+40]=s_temp[i];
		}
	}
	/* END: copy changed temp values in original array */
	
	t_stop = gettime();
	t_short_term_filtering += calc_timediff_ms(t_start,t_stop);
	
	#ifdef _DEBUG
		fprintf(stderr, "########POST AUSFUEHRUNG GSM_SHOT_TERM_4\n");
		for(count_1=0;count_1<8;count_1++)
		{
			fprintf(stderr, "rrp[%d]=%d\n", count_1, LARp[count_1]);
		}
		for(count_1=0;count_1<9;count_1++)
		{
			fprintf(stderr, "S->v[%d]=%d\n", count_1, S->v[count_1]);
		}
		for(count_1=0;count_1<160;count_1++)
		{
			fprintf(stderr, "sr[%d]=%d\n",count_1,s[count_1]);
		}
	#endif
	
	#ifdef _PRINT_TIMES	
	/* print times*/
	fprintf(stderr, "Running times (%d sw-threads, %d hw-threads):\n",swts, hwts);
	
	fprintf(stderr,   
		"\tgenerate threads\t: %lu ms\n"
		"\coefficients\t\t: %lu ms\n"
		"\short_term_syntesise_filtering\t\t: %lu ms\n"
		"\tterminate threads\t: %lu ms\n"
		"\tsum\t: %lu ms\n",
		t_generate_threads, 
		t_coefficients,
		t_short_term_filtering, 
		t_terminate_threads,
		t_generate_threads+t_coefficients+t_short_term_filtering+t_terminate_threads
	);
	#endif
}
