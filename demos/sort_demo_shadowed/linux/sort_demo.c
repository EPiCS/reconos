#include "reconos.h"
#include "mbox.h"

#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include "config.h"
#include "merge.h"
#include "data.h"
#include "bubblesort.h"
#include "sort8k.h"
#include "timing.h"



#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000
#define PAGES_PER_THREAD 2

#define BLOCK_SIZE PAGE_SIZE*PAGES_PER_THREAD

#define MAX_BURST_SIZE 1023
#define MAX_THREADS 32

#define TO_WORDS(x) ((x)/4)
#define TO_PAGES(x) ((x)/PAGE_SIZE)
#define TO_BLOCKS(x) ((x)/(PAGE_SIZE*PAGES_PER_THREAD))

// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt[MAX_THREADS];


// mailboxes
struct mbox mb_start;
struct mbox mb_stop;

unsigned int* malloc_page_aligned(unsigned int pages)
{
	unsigned int * temp = malloc ((pages+1)*PAGE_SIZE);
	unsigned int * data = (unsigned int*)(((unsigned int)temp / PAGE_SIZE + 1) * PAGE_SIZE);
	return data;
}

// size is given in words, not bytes!
void print_data(unsigned int* data, unsigned int size)
{
	int i;
	for (i=0; i<size; i++)
	{
		printf("(%04d) %04d \t", i, data[i]);
		if ((i+1)%4 == 0) printf("\n");
	}
	printf("\n");
}


void print_mmu_stats()
{
	uint32 hits,misses,pgfaults;

	reconos_mmu_stats(&hits,&misses,&pgfaults);

	printf("MMU stats: TLB hits: %d    TLB misses: %d    page faults: %d\n",hits,misses,pgfaults);
}


void print_help()
{
  printf(
"ReconOS v3 sort demo application.\n"
"Sorts a buffer full of data with a variable number of sw and hw threads.\n"
"\n"
"Usage:\n"
"\tsort_demo <-h|--help>\n"
"\tsort_demo <num_hw_threads> <num_sw_threads> <num_of_blocks>\n"
"\n"
"Size of a block in bytes: %i\n",
PAGE_SIZE*PAGES_PER_THREAD
);
}

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
int main(int argc, char ** argv)
{
	int i;
	int ret;
	int hw_threads;
	int sw_threads;
	int running_threads;
	int buffer_size;
	unsigned int *data, *copy;

	timing_t t_start;
    timing_t t_stop;
	ms_t t_generate = 0;
	ms_t t_sort = 0;
	ms_t t_merge = 0;
	ms_t t_check = 0;

	//
	// Install signal handler for segfaults
	//
	struct sigaction act={
			.sa_sigaction = sigsegv_handler,
			.sa_flags =  SA_SIGINFO
	};
	sigaction(SIGSEGV, &act, NULL);

	if ((argc < 4) || (argc > 4))
	{
	  print_help();
	  exit(1);
	}
	// we have exactly 3 arguments now...
	hw_threads = atoi(argv[1]);
	sw_threads = atoi(argv[2]);

	// Base unit is bytes. Use macros TO_WORDS, TO_PAGES and TO_BLOCKS for conversion.
	buffer_size = atoi(argv[3])*PAGE_SIZE*PAGES_PER_THREAD;

	running_threads = hw_threads + sw_threads;

	//int gettimeofday(struct timeval *tv, struct timezone *tz);

	// init mailboxes
	mbox_init(&mb_start,TO_BLOCKS(buffer_size));
    mbox_init(&mb_stop ,TO_BLOCKS(buffer_size));

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_start;	  	
        res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_stop;
#ifndef HOST_COMPILE
	// init reconos and communication resources
	reconos_init_autodetect();


	printf("Creating %i hw-threads: ", hw_threads);
	fflush(stdout);
	for (i = 0; i < hw_threads; i++)
	{
	  printf(" %i",i);fflush(stdout);
	  reconos_hwt_setresources(&(hwt[i]),res,2);
	  reconos_hwt_create(&(hwt[i]),i,NULL);
	}
	printf("\n");
#endif
	// init software threads
	printf("Creating %i sw-threads: ",sw_threads);
	fflush(stdout);
	for (i = 0; i < sw_threads; i++)
	{
	  printf(" %i",i);fflush(stdout);
	  pthread_attr_init(&swt_attr[i]);
	  pthread_create(&swt[i], &swt_attr[i], sort_thread_shmem, (void*)res);
	}
	printf("\n");


	//print_mmu_stats();

	// create pages and generate data
	t_start = gettime();

	printf("malloc page aligned ...\n");
	data = malloc_page_aligned(TO_PAGES(buffer_size));
	copy = malloc_page_aligned(TO_PAGES(buffer_size));
	printf("generating %i words of data ...\n", TO_WORDS(buffer_size));
	generate_data( data, TO_WORDS(buffer_size));
	memcpy(copy,data,buffer_size);

	t_stop = gettime();
	t_generate = calc_timediff_ms(t_start,t_stop);

	// print data of first page
	printf("Printing of generated data skipped. \n");
	//print_data(data, TO_WORDS(buffer_size));


	// Start sort threads
	t_start = gettime();

	printf("Putting %i blocks into job queue: ", TO_BLOCKS(buffer_size));
	fflush(stdout);
	for (i=0; i<TO_BLOCKS(buffer_size); i++)
	{
	  //printf(" %i",i);fflush(stdout);
	  mbox_put(&mb_start,(unsigned int)data+(i*BLOCK_SIZE));
	}
	printf("\n");

	// Wait for results
	printf("Waiting for %i acknowledgements: ", TO_BLOCKS(buffer_size));
	fflush(stdout);
	for (i=0; i<TO_BLOCKS(buffer_size); i++)
	{
	  //printf(" %i",i);fflush(stdout);
	  ret = mbox_get(&mb_stop);
	}  
	printf("\n");

	t_stop = gettime();
	t_sort = calc_timediff_ms(t_start,t_stop);


	// merge data
	t_start = gettime();	

	printf("Merging sorted data slices...\n");
	unsigned int * temp = malloc_page_aligned(TO_PAGES(buffer_size));
	//printf("Data buffer at address %p \n", (void*)data);
	//printf("Address of temporary merge buffer: %p\n", (void*)temp);
	//printf("Total size of data in bytes: %i\n",buffer_size);
	//printf("Size of a sorting block in bytes: %i\n",BLOCK_SIZE);
	if (temp == NULL){
		printf ("Buffer allocation failed. Exiting...\n");
		exit(1);
	}
	data = recursive_merge( data, 
				temp,
				TO_WORDS(buffer_size), 
				TO_WORDS(BLOCK_SIZE), 
				simple_merge 
				);

	t_stop = gettime();
	t_merge = calc_timediff_ms(t_start,t_stop);
	
	// check data
	//data[0] = 6666; // manual fault
	t_start = gettime();

	printf("Checking sorted data: ... ");
	fflush(stdout);
	ret = check_data( data, copy, TO_WORDS(buffer_size));
	if (ret >= 0)
	  {
	    printf("failure at word index %i\n", -ret);
	    printf("expected 0x%08X    found 0x%08X\n",copy[ret],data[ret]);
            printf("dumping the first 2048 words:\n");
            for(i = 0; i < 2048; i++){
              printf("%08X ",data[i]);
              if((i % 8) == 7) printf("\n");
            }
	  }
	else
	  {
	    printf("success\n");
	    //print_data(data, TO_WORDS(buffer_size));
	  }

	t_stop = gettime();
	t_check = calc_timediff_ms(t_start,t_stop);

	// terminate all threads
	printf("Sending terminate message to %i threads:", running_threads);
	fflush(stdout);
	for (i=0; i<running_threads; i++)
	{
	  printf(" %i",i);fflush(stdout);
	  mbox_put(&mb_start,UINT_MAX);
	}
	printf("\n");

	printf("Waiting for termination...\n");
	for (i=0; i<hw_threads; i++)
	{
	  pthread_join(hwt[i].delegate,NULL);
	}

	for (i=0; i<sw_threads; i++)
	{
	  pthread_join(swt[i],NULL);
	}

	printf("\n");

#ifndef HOST_COMPILE
	print_mmu_stats();
#endif

	printf( "Running times (size: %d words, %d hw-threads, %d sw-threads):\n"
            "\tGenerate data: %lu ms\n"
            "\tSort data    : %lu ms\n"
            "\tMerge data   : %lu ms\n"
            "\tCheck data   : %lu ms\n"
            "Total computation time (sort & merge): %lu ms\n",
		TO_WORDS(buffer_size), hw_threads, sw_threads,
		t_generate, t_sort, t_merge, t_check, t_sort + t_merge );
	

	//free(data);
	// Memory Leak on variable data!!!
	
	return 0;
}

