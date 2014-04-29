/*
 * rawcaudio_hybrid.c
 *
 * Modified rawcaudio.c for using in MiBenchHybrid
 *
 * Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
 * 
 * History:	08.03.2013 Alexander Sprenger created
 * 
 * */

/* testc - Test adpcm coder */

#include "adpcm.h"
#include <stdio.h>

//ReconOS Headers
#include "reconos.h"
#include "rq.h"

//MiBenchHybrid Headers
#include "../../../inc/mibench_hybrid.h"

#include <stdint.h>
#include <limits.h>
#include <pthread.h>
#include "timing_upb.h"

//signalhandler
#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/* define/undefine for additional output */
//#define _DEBUG
#define _MIBENCHOUTPUT
#define _PRINT_TIMES

/* Number of Words in ReconOSqueues */
#define INDATA_LEN 4
#define OUTDATA_LEN 1

// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt[MAX_THREADS];

// ReconOSqueues
rqueue rq_SENDING;
rqueue rq_RECIEVE;

//Number of Samples to convert per run
#define NSAMPLES 26208 

/* rawcaudio Softwarethread */
void *rawcaudio_swt(void* data)
{
		uint32 indata[INDATA_LEN];
		uint32 outdata[OUTDATA_LEN];
		
		struct reconos_resource *res  = (struct reconos_resource*) data;
		
		rqueue *rq_start = res[0].ptr;
		rqueue *rq_stop  = res[1].ptr;
				
		short *inp;		//pointer to the first position of the input array
		char *outp;		//pointer to the first position of the output array
		int samples;	//number of samples
		struct adpcm_state state;	//previous adpcm_state
		
		int val;
		int i;		
		
		//pthread_t self = pthread_self();
		//fprintf(stderr, "SW Thread %lu: running\n", self);
		
		while(1)
		{
			//recieve incoming reconosqueue	
			val = rq_receive(rq_start, indata, INDATA_LEN*sizeof(uint32)); 
			if (indata[0] == UINT_MAX)
			{
				//fprintf(stderr, "SW Thread %lu: Got exit command from mailbox %p.\n", self, rq_start);
				pthread_exit((void*)0);
			}
			else
			{
				//get values from reconosqueue
				inp  	= (short *) indata[0];
				outp 	= (char *) indata[1];
				samples = (int) indata[2];
				samples &= 0x7FFFFFFF;		//highest is 1 for adpcm encoder so its have to be filtered
				state.valprev = (short) (indata[3] >> 16);
				state.index = (char) indata[3];
				//fprintf(stderr, "state.valprev=%d state.index=%d\n", state.valprev, state.index);
				
				//adpcm_coder
				adpcm_coder(inp, outp, samples, &state);
			}
			
			//send reconosqueue for acknowledge 
			outdata[0] = 0;
			outdata[0] |= ( ((uint32)state.valprev) << 16);
			outdata[0] |= (uint32) state.index;
			rq_send(rq_stop, outdata, OUTDATA_LEN*sizeof(uint32));
		}
}

void print_help()
{
	fprintf(stderr, 
		"MiBenchHybrid rawcaudio application\n"
		"\n"
		"USAGE:\n"
		"\tMiBench version:\n"
		"\trawcaudio\n"
		"\n"
		"\tMiBenchHybrid version:\n"
		"\trawcaudio_hybrid <number of software threads> <number of hardware threads>\n"
		"hardware threads max =%d running threads max=%d\n\n", NADPCM_THREADS, MAX_THREADS		
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
    fprintf(stderr, "SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
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
    struct adpcm_state state;

	char	abuf[NSAMPLES/2];
	short	sbuf[NSAMPLES];
    
    int n;
    
    //MiBenchHybrid variables
    int hw_threads;
	int sw_threads;
	int running_threads;
	
	int rawcaudio_hybrid = TRUE;
	
	uint32 indata[INDATA_LEN];
	uint32 outdata[OUTDATA_LEN];
	
	int ret;
	int i;
	
	//timing variables
	timing_t t_start, t_stop;
	ms_t t_generate_threads = 0;
	ms_t t_read_data = 0;
	ms_t t_write_data = 0;
	ms_t t_encode_data = 0;
	ms_t t_terminate_threads = 0;
	
	/* control number of commandlineargs*/
	if(argc == 1)
	{
		rawcaudio_hybrid = FALSE;
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
			rawcaudio_hybrid = FALSE;
		}
		else if (hw_threads > NADPCM_THREADS)
		{
			fprintf(stderr, "To many Hardwarethreads!\n\n");
			print_help();
			exit(1);
		}
		else if (running_threads > MAX_THREADS)
		{
			fprintf(stderr, "To many Threads!\n\n");
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
	
	
	if( rawcaudio_hybrid )
	{	
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
		fprintf(stderr, "Creating %i hw-threads: ", hw_threads);
		fflush(stdout);
		#endif
		for (i = 0; i < hw_threads; i++)
		{
			#ifndef _MIBENCHOUTPUT
			fprintf(stderr, " %i",i);fflush(stdout);
			#endif
			reconos_hwt_setresources(&(hwt[i]),res,2);
			reconos_hwt_create(&(hwt[i]),FIRST_ADPCM_SLOT+i,NULL);
		}
		#ifndef _MIBENCHOUTPUT
		fprintf(stderr, "\n");
		#endif
		
		// init software threads
		#ifndef _MIBENCHOUTPUT
		fprintf(stderr, "Creating %i sw-threads: ",sw_threads);
		fflush(stdout);
		#endif
		for (i = 0; i < sw_threads; i++)
		{
		  #ifndef _MIBENCHOUTPUT
		  fprintf(stderr, " %i",i);fflush(stdout);
		  #endif
		  pthread_attr_init(&swt_attr[i]);
		  pthread_create(&swt[i], &swt_attr[i], rawcaudio_swt, (void*)res);
		}
		#ifndef _MIBENCHOUTPUT
		fprintf(stderr, "\n");		
		#endif
		
		t_stop = gettime();
		t_generate_threads = calc_timediff_ms(t_start,t_stop);
	}

    while(1) 
    {
		t_start = gettime();
		
		//read data from stdin
		n = read(0, sbuf, NSAMPLES*2);
		if ( n < 0 ) {
			perror("input file");
			exit(1);
		}
		if ( n == 0 ) break;
	
		t_stop = gettime();
		t_read_data += calc_timediff_ms(t_start,t_stop);
		
		//encode data
		if( rawcaudio_hybrid )
		{
			t_start = gettime();
			
			//build reconosqueue messages
			indata[0] = (uint32) sbuf;
			indata[1] = (uint32) abuf;
			indata[2] = (uint32) n/2;
			indata[2] |= 0x80000000; 		//we want to encode adpcm so the highest bit have to be 1
			indata[3] = 0;
			indata[3] |= ( ((uint32)state.valprev) << 16);
			indata[3] |= (uint32) state.index;
			
			#ifndef _MIBENCHOUTPUT
			fprintf(stderr, "PRE re_send: indata(%X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3]);
			#endif
			//sending rq
			rq_send(&rq_SENDING, indata, INDATA_LEN*sizeof(uint32));
			
			#ifndef _MIBENCHOUTPUT
			fprintf(stderr, "POST re_send: indata(%X, %X, %X, %X)\n", indata[0], indata[1], indata[2], indata[3]);
			
			fprintf(stderr, "PRE re_receive: outdata(%X)\n", outdata[0]);
			#endif
			//receiving rq
			ret = rq_receive(&rq_RECIEVE, outdata, OUTDATA_LEN*sizeof(uint32));
			
			#ifndef _MIBENCHOUTPUT
			fprintf(stderr, "POST re_receive: outdata(%X)\n", outdata[0]);
			#endif
			
			if(ret == -1)
			{
				fprintf(stderr, "ERROR: rq_recieve bigger than expected!\n");
				exit(1);
			}
			state.valprev = (short) (outdata[0] >> 16);
			state.index = (char) outdata[0];
			
			t_stop = gettime();
			t_encode_data += calc_timediff_ms(t_start,t_stop);
		}
		else
		{
			t_start = gettime();
			
			//fprintf(stderr, "state.valprev=%d state.index=%d\n", state.valprev, state.index);
			adpcm_coder(sbuf, abuf, n/2, &state);
			
			t_stop = gettime();
			t_encode_data += calc_timediff_ms(t_start,t_stop);
		}
		
		t_start = gettime();
		
		//write data to stdout
		write(1, abuf, n/4);
		
		t_stop = gettime();
		t_write_data += calc_timediff_ms(t_start,t_stop);
    }
    
    if(rawcaudio_hybrid)
    {
		t_start = gettime();
		
		// terminate all threads
		#ifndef _MIBENCHOUTPUT
		fprintf(stderr, "Sending terminate message to %i threads:\n", running_threads);
		fflush(stdout);
		#endif
		for (i=0; i<running_threads; i++)
		{
		  #ifndef _MIBENCHOUTPUT
		  fprintf(stderr, " %i",i);fflush(stdout);
		  #endif
		  indata[0] = UINT_MAX;
		  indata[1] = UINT_MAX;
		  indata[2] = UINT_MAX;
		  indata[3] = UINT_MAX;
		
		  rq_send(&rq_SENDING, indata, INDATA_LEN*sizeof(uint32));
		}
		#ifndef _MIBENCHOUTPUT
		fprintf(stderr, "\n");
		
		fprintf(stderr, "Waiting for termination...\n");
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
		fprintf(stderr, "\n");
		#endif
		
		t_stop = gettime();
		t_terminate_threads += calc_timediff_ms(t_start,t_stop);
	}
    
    fprintf(stderr, "Final valprev=%d, index=%d\n",
	    state.valprev, state.index);
	    
	#ifdef _PRINT_TIMES	
	/* print times*/
	if(rawcaudio_hybrid)
	{
		fprintf(stderr, "Running times (%d sw-threads, %d hw-threads):\n",sw_threads, hw_threads);
	}
	else
	{
		fprintf(stderr, "Running times (normal MiBench):\n");
	}
	fprintf(stderr,  
		"\tgenerate threads\t: %lu ms\n"
		"\tread data\t\t: %lu ms\n"
		"\tencode data\t\t: %lu ms\n"
		"\twrite data\t\t: %lu ms\n"
		"\tterminate threads\t: %lu ms\n"
		"\tsum\t: %lu ms\n",
		t_generate_threads, 
		t_read_data,
		t_encode_data, 
		t_write_data,
		t_terminate_threads,
		t_generate_threads+t_read_data+t_encode_data+t_write_data+t_terminate_threads
	);
	#endif 
	 
    exit(0);
}
