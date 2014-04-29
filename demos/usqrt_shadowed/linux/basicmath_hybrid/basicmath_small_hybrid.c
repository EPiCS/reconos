/*
 * basicmath_small_hybrid.c
 *
 * Modified basicmath_small.c for using in MiBenchHybrid
 *
 * Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
 * 
 * History:	08.03.2013 Alexander Sprenger created
 * 
 * */

#include "snipmath.h"
#include <math.h>

//ReconOS Headers
#include "reconos.h"
#include "rq.h"

//MiBenchHybrid Headers
#include "../../inc/mibench_hybrid.h"

#include <stdint.h>
#include <stdio.h>
#include <limits.h>
#include <pthread.h>
#include "timing.h"

//signalhandler
#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/* define/undefine for additonal output */
//#define _DEBUG
#define _MIBENCHOUTPUT
#define _PRINT_TIMES

/* The printf's may be removed to isolate just the math calculations */
//#define printf(...)

#define NUMOFVALUES 1002					/* Number of Values to calculate */
#define PAGESSIZE_DWORDS 16384				/* capacity of local ram used in hte hardwarethread */
#define PAGESSIZE_BYTES	PAGESSIZE_DWORDS*4	/* Pagesize in byte */

#define INDATA_LEN 3		/* Len of ReconOSqueue to the Hardwarthread in DWords */
#define OUTDATA_LEN 1		/* Len of ReconOSqueue from the Hardwarethread in DWORD */

// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt[MAX_THREADS];

// reconosqueues
rqueue rq_SENDING;
rqueue rq_RECIEVE;

void *usqrt_swt(void* data)
{
		uint32 indata[INDATA_LEN];
		uint32 outdata[OUTDATA_LEN];
		
		struct reconos_resource *res  = (struct reconos_resource*) data;
		
		rqueue *rq_start = res[0].ptr;
		rqueue *rq_stop  = res[1].ptr;
				
		unsigned long *inp;		//pointer to the first position of the input values
		struct int_sqrt *outp;	//pointer to the first position of the output array
		int cnt;				//number of values to calculate
		
		int val;
		int i;		
		
		//pthread_t self = pthread_self();
		//printf("SW Thread %lu: running\n", self);
		
		while(1)
		{
			//recieve incoming reconosqueue	
			val = rq_receive(rq_start, indata, INDATA_LEN*sizeof(uint32)); 
			if (indata[0] == UINT_MAX)
			{
				//printf("SW Thread %lu: Got exit command from mailbox %p.\n", self, mb_start);
				pthread_exit((void*)0);
			}
			else
			{
				//get values from reconosqueue
				inp  = (unsigned long *) indata[0];
				outp = (struct int_sqrt *) indata[1];
				cnt  = (int) indata[2];
				
				//calculate sqaure roots
				for(i=0;i<cnt;i++)
				{
					usqrt(inp[i], &outp[i]);
				}
			}
			
			//send reconosqueue for acknowledge 
			outdata[0] = (uint32) outp;
			rq_send(rq_stop, outdata, OUTDATA_LEN*sizeof(uint32));
		}
}

void print_help()
{
	printf(
		"MiBenchHybrid basicmath_small application\n"
		"\n"
		"USAGE:\n"
		"\tMiBench version:\n"
		"\t\tbasicmath_small\n"
		"\n"
		"\tMiBenchHybrid version:\n"
		"\t\tbasicmath_small <number of software threads> <number of hardware threads>\n"
	);	
}

#ifdef _DEBUG
//
// Signal handler for SIGSEGV
// Get as much information to help in debugging as possible!
//
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context){
	ucontext_t* uc = (ucontext_t*) context;

    // Yeah, i know using printf in a signal context is not save.
    // But with a SIGSEGV the programm is messed up anyway, so what?
    printf("SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
#ifndef HOST_COMPILE
    		(void*)uc->uc_mcontext.regs.pc,
#else
    		(void*)uc->uc_mcontext.gregs[14],
#endif
    		(void*) siginfo->si_addr);
    exit(1);
}
#endif

int main(int argc, char *argv[])
{
	double  a1 = 1.0, b1 = -10.5, c1 = 32.0, d1 = -30.0;
	double  a2 = 1.0, b2 = -4.5,  c2 = 17.0, d2 = -30.0;
	double  a3 = 1.0, b3 = -3.5,  c3 = 22.0, d3 = -31.0;
	double  a4 = 1.0, b4 = -13.7, c4 = 1.0,  d4 = -35.0;
	double  x[3];
	double X;
	int solutions;
	int i;
	unsigned long l = 0x3fed0169L;
	struct int_sqrt q;
	long n = 0;
	
	//MiBenchhybrid variables
	int j;
	int cond;
	int num_of_runs;
	int pages = 0;
	int remain = 0;
	int cnt = 0;
	int cnt2 = 0;
	int number_of_rq_sends = 0;
	unsigned long *values;
	struct int_sqrt *results;
	
	int hw_threads;
	int sw_threads;
	int running_threads;
	
	int basicmath_hybrid = TRUE;
	
	uint32 indata[INDATA_LEN];
	uint32 outdata[OUTDATA_LEN];
	
	int ret;
	
	//timing variables
	timing_t t_start, t_stop;
	ms_t t_cubic = 0;
	ms_t t_sqrt = 0;
	ms_t t_angle = 0;
	ms_t t_generate_threads = 0;
	ms_t t_generate_data = 0;
	ms_t t_sqrt_print = 0;
	
	
	/* control number of commandlineargs*/
	if(argc == 1)
	{
		basicmath_hybrid = FALSE;
	}	
	else if ((argc < 3) || (argc > 3))
	{
	  print_help();
	  exit(1);
	}
	else
	{
		/* get arguments from commandoline */
		sw_threads = atoi(argv[1]);
		hw_threads = atoi(argv[2]);
		running_threads = sw_threads + hw_threads;
		if (running_threads == 0)
		{
			basicmath_hybrid = FALSE;
		}
		else if (hw_threads > NUSQRT_THREADS)
		{
			printf("To many Hardwarethreads!\n\n");
			print_help();
			exit(1);
		}
		else if (running_threads > MAX_THREADS)
		{
			printf("To many Threads!\n\n");
			print_help();
			exit(1);
		}
	}
	
	#ifdef _DEBUG
	//
	// Install signal handler for segfaults
	//
	struct sigaction act={
			.sa_sigaction = sigsegv_handler,
			.sa_flags =  SA_SIGINFO
	};
	sigaction(SIGSEGV, &act, NULL);
	#endif
	
	if(basicmath_hybrid)
	{  
		t_start = gettime();
		
		//allocate memory for data
		values  = (unsigned long *) malloc(NUMOFVALUES * sizeof(unsigned long));
		results = (struct int_sqrt *) malloc(NUMOFVALUES * sizeof(struct int_sqrt));
		
		//generate data
		l = 0x3fed0169L;
		for( i=0 ; i<NUMOFVALUES ; i++ )
		{
			if(i<(NUMOFVALUES-1))
			{
				values[i] = i;
			}
			else
			{
				values[i] = l++;
			}
			results[i].sqrt = 0;
			results[i].frac = 0;
		}
		
		t_stop = gettime();
		t_generate_data = calc_timediff_ms(t_start,t_stop);
		
		t_start = gettime();
		
		/* reconos init*/
		rq_init(&rq_SENDING, 10);
		rq_init(&rq_RECIEVE, 10);
		  
		res[0].type = RECONOS_TYPE_RQ;
		res[0].ptr  = &rq_SENDING;
		res[1].type = RECONOS_TYPE_RQ;
		res[1].ptr  = &rq_RECIEVE;
		
		reconos_init_autodetect();
		
		/* creating hw_threads */
		#ifndef _MIBENCHOUTPUT
		printf("Creating %i hw-threads: ", hw_threads);
		fflush(stdout);
		#endif
		for (i = 0; i < hw_threads; i++)
		{
		  #ifndef _MIBENCHOUTPUT
		  printf(" %i",i);fflush(stdout);
		  #endif
		  reconos_hwt_setresources(&(hwt[i]),res,2);
		  reconos_hwt_create(&(hwt[i]),FIRST_USQRT_SLOT+i,NULL);
		}
		#ifndef _MIBENCHOUTPUT
		printf("\n");
		#endif
		
		// init software threads
		#ifndef _MIBENCHOUTPUT
		printf("Creating %i sw-threads: ",sw_threads);
		fflush(stdout);
		#endif
		for (i = 0; i < sw_threads; i++)
		{
		  #ifndef _MIBENCHOUTPUT
		  printf(" %i",i);fflush(stdout);
		  #endif
		  pthread_attr_init(&swt_attr[i]);
		  pthread_create(&swt[i], &swt_attr[i], usqrt_swt, (void*)res);
		}
		#ifndef _MIBENCHOUTPUT
		printf("\n");		
		#endif
		
		t_stop = gettime();
		t_generate_threads = calc_timediff_ms(t_start,t_stop);
	}
	
	t_start = gettime();
	
	#ifndef _DEBUG	
	/* solve soem cubic functions */
	printf("********* CUBIC FUNCTIONS ***********\n");
	/* should get 3 solutions: 2, 6 & 2.5   */
	SolveCubic(a1, b1, c1, d1, &solutions, x);  
	printf("Solutions:");
	for(i=0;i<solutions;i++)
		printf(" %f",x[i]);
	printf("\n");
	/* should get 1 solution: 2.5           */
	SolveCubic(a2, b2, c2, d2, &solutions, x);  
	printf("Solutions:");
	for(i=0;i<solutions;i++)
		printf(" %f",x[i]);
	printf("\n");
	SolveCubic(a3, b3, c3, d3, &solutions, x);
	printf("Solutions:");
	for(i=0;i<solutions;i++)
		printf(" %f",x[i]);
	printf("\n");
	SolveCubic(a4, b4, c4, d4, &solutions, x);
	printf("Solutions:");
	for(i=0;i<solutions;i++)
		printf(" %f",x[i]);
	printf("\n");
	/* Now solve some random equations */
	for(a1=1;a1<10;a1++) {
		for(b1=10;b1>0;b1--) {
			for(c1=5;c1<15;c1+=0.5) {
				for(d1=-1;d1>-11;d1--) {
					SolveCubic(a1, b1, c1, d1, &solutions, x);  
					printf("Solutions:");
					for(i=0;i<solutions;i++)
						printf(" %f",x[i]);
					printf("\n");
				}
			}
		}
	}
	#endif
	
	t_stop = gettime();
	t_cubic = calc_timediff_ms(t_start,t_stop);
	  
	printf("********* INTEGER SQR ROOTS ***********\n");
	/* perform some integer square roots */
	if(basicmath_hybrid)
	{
		t_start = gettime();		
		
		//calculate how many times the calculate have to be initiated
		num_of_runs = NUMOFVALUES / PAGESSIZE_DWORDS;
		if((NUMOFVALUES % PAGESSIZE_DWORDS) != 0)
		{
			//if there is an rest num_of_runs have to be incremented
			num_of_runs++;
		}
		
		//if num_of_runs < running_threads split data to run all threads
		if (num_of_runs < running_threads)
		{
			num_of_runs = running_threads;
		}
		
		if((NUMOFVALUES % num_of_runs) == 0)
		{
			//if there is no rest all runs have got the same number of values to calculate
			cnt = NUMOFVALUES / num_of_runs;
			cnt2 = cnt;
		}
		else
		{
			//if there is a rest number of values differs by the last run
			cnt = NUMOFVALUES / num_of_runs;  //PAGESSIZE_DWORDS;
			cnt2 = NUMOFVALUES % num_of_runs; //NUMOFVALUES % PAGESSIZE_DWORDS;
		}
		
		//calculate sqrts
		#ifndef _MIBENCHOUTPUT
		printf("START calulate: num_of_runs=%d cnt=%d\n",num_of_runs,cnt);
		#endif
		j=1;
		number_of_rq_sends = 0;
		while(num_of_runs > 0)
		{
			//getting condition for sending reconosqueues
			if(num_of_runs <= running_threads)
			{
				cond = num_of_runs;
			}
			else
			{
				cond = running_threads;
			}
			
			//build and send reconosqueue
			for(i=0;i<cond;i++)
			{
				indata[0] = (uint32) &values[number_of_rq_sends*cnt]; 	//inp_addr
				indata[1] = (uint32) &results[number_of_rq_sends*cnt];	//outp_addr
				
				if((num_of_runs-i)==1)
				{
					indata[2] = (uint32) cnt2;	//count
				}
				else
				{
					indata[2] = (uint32) cnt;	//count
				}
			
				rq_send(&rq_SENDING, indata, INDATA_LEN*sizeof(uint32));
				number_of_rq_sends++;
			}
			
			//recieve reconosqueues
			for(i=0;i<cond;i++)
			{
				ret = rq_receive(&rq_RECIEVE, outdata, OUTDATA_LEN*sizeof(uint32));
				if(ret == -1)
				{
					printf("ERROR: rq_recieve bigger than expected!\n");
				}
			}
			num_of_runs -= running_threads;
			j++;
		}
	
		t_stop = gettime();
		t_sqrt = calc_timediff_ms(t_start,t_stop);
		
		t_start = gettime();
		
		//print calculated sqrts
		for(i=0;i<NUMOFVALUES;i++)
		{
			if(i<NUMOFVALUES-1)
			{
				//printf("sqrt(%3d) = %3d,%d\n",i, results[i].sqrt, results[i].frac);
				printf("sqrt(%3d) = %2d\n",values[i], results[i].sqrt);
			}
			else
			{
				printf("\nsqrt(%lX) = %X\n", values[i], results[i].sqrt);
			}
		}
		
		t_stop = gettime();
		t_sqrt_print = calc_timediff_ms(t_start,t_stop);
		
		// terminate all threads
		#ifndef _MIBENCHOUTPUT
		printf("Sending terminate message to %i threads:\n", running_threads);
		fflush(stdout);
		#endif
		for (i=0; i<running_threads; i++)
		{
		  #ifndef _MIBENCHOUTPUT
		  printf(" %i",i);fflush(stdout);
		  #endif
		  indata[0] = UINT_MAX;
		  indata[1] = UINT_MAX;
		  indata[2] = UINT_MAX;
			
		  rq_send(&rq_SENDING, indata, INDATA_LEN*sizeof(uint32));
		}
		#ifndef _MIBENCHOUTPUT
		printf("\n");
		
		printf("Waiting for termination...\n");
		#endif
		for (i=0; i<hw_threads; i++)
		{
		  pthread_join(hwt[i].delegate,NULL);
		}
		for (i=0; i<sw_threads; i++)
		{
		  pthread_join(swt[i],NULL);
		}
		#ifndef _MIBENCHOUTPUT
		printf("\n");
		
		printf("XXXX - basicmath_hybrid end - XXXX\n");
		#endif
	}
	else
	{
		t_start = gettime();
		
		printf("********* INTEGER SQR ROOTS ***********\n");
		/* perform some integer square roots */
		for (i = 0; i < 1001; ++i)
		{
			usqrt(i, &q);
			// remainder differs on some machines
			// printf("sqrt(%3d) = %2d, remainder = %2d\n",
			printf("sqrt(%3d) = %2d\n",
				i, q.sqrt);
		}
		usqrt(l, &q);
		//printf("\nsqrt(%lX) = %X, remainder = %X\n", l, q.sqrt, q.frac);
		printf("\nsqrt(%lX) = %X\n", l, q.sqrt);
		
		t_stop = gettime();
		t_sqrt = calc_timediff_ms(t_start,t_stop);
	}

	t_start = gettime();
	
	#ifndef _DEBUG
	printf("********* ANGLE CONVERSION ***********\n");
	/* convert some rads to degrees */
	for (X = 0.0; X <= 360.0; X += 1.0)
		printf("%3.0f degrees = %.12f radians\n", X, deg2rad(X));
	puts("");
	for (X = 0.0; X <= (2 * PI + 1e-6); X += (PI / 180))
		printf("%.12f radians = %3.0f degrees\n", X, rad2deg(X));
	#endif
	
	t_stop = gettime();
	t_angle = calc_timediff_ms(t_start,t_stop);

	#ifdef _PRINT_TIMES	
	/* print times*/
	if(basicmath_hybrid)
	{
		fprintf(stderr, "Running times (%d sw-threads, %d hw-threads):\n",sw_threads, hw_threads);
	}
	else
	{
		fprintf(stderr, "Running times (normal MiBench):\n");
	}
	fprintf(stderr, 
		"\tgenerate data\t\t: %lu ms\n"
		"\tgenerate threads\t: %lu ms\n"
		"\tsolve cubic functions\t: %lu ms\n"
		"\tcalculate sqrts\t\t: %lu ms\n"
		"\tprinting sqrts\t\t: %lu ms\n"
		"\tdo angle conversions\t: %lu ms\n"
		"\tsum\t: %lu ms\n",
		t_generate_data,
		t_generate_threads, 
		t_cubic,
		t_sqrt, 
		t_sqrt_print,
		t_angle,
		t_generate_data+t_generate_threads+t_cubic+t_sqrt+t_sqrt_print+t_angle
	);
	#endif
	
	return 0;
}
