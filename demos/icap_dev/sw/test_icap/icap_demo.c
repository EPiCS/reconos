#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>
#include <signal.h>

// ReconOS
#include "reconos.h"
#include "mbox.h"

#include "timing.h"

#include "icap_demo.h"




struct cmd_arguments_t g_arguments;


struct reconos_resource res[NUM_SLOTS][2];
struct reconos_hwt hwt[NUM_SLOTS];
struct mbox mb_in[NUM_SLOTS];
struct mbox mb_out[NUM_SLOTS];

struct pr_bitstream_t pr_bit[NUM_SLOTS][2];

//------------------------------------------------------------------------------
// if clock gating is used, this function enables (disables) the clock
//------------------------------------------------------------------------------
void clock_enable(int slot, int enable)
{
  reconos_slot_reset(slot + 8, enable);
}


//------------------------------------------------------------------------------
// load partial bitfile via hardware icap thread
// This function returns 0 if an error occurred and 1 if successful
//------------------------------------------------------------------------------
int hw_icap_load(int slot, int thread_id)
{
	int ret;

  uint32_t* addr = pr_bit[slot][thread_id].block;
  unsigned int size = (unsigned int)pr_bit[slot][thread_id].length * 4;

  ret = hw_icap_write(addr, size);

  if(ret == 0) {
    printf("Could not write to ICAP using HWT_ICAP controller\n");
    return 0;
  }

	return 1;
}

//------------------------------------------------------------------------------
// loads bitstream via ICAP
// Returns 1 if successfull, 0 otherwise
//------------------------------------------------------------------------------
int sw_icap_load(int slot, int thread_id)
{
  if( sw_icap_write(pr_bit[slot][thread_id].block, pr_bit[slot][thread_id].length * 4) == 0) {
    printf("Could not write to ICAP using XPS_HWICAP controller\n");

    return 0;
  }

  return 1;
}

//------------------------------------------------------------------------------
// loads bitstream via linux ICAP driver
// Returns 1 if successfull, 0 otherwise
//------------------------------------------------------------------------------
int linux_icap_load(int slot, int thread_id)
{
  int ret = -2;

  if(slot == 1) {
    if(thread_id == ADD)
      ret = system("cat partial_bitstreams/partial_add.bin > /dev/icap0");
    else if(thread_id == SUB)
      ret = system("cat partial_bitstreams/partial_sub.bin > /dev/icap0");
  } else {
    if(thread_id == ADD)
      ret = system("cat partial_bitstreams/partial_mul.bin > /dev/icap0");
    else if(thread_id == SUB)
      ret = system("cat partial_bitstreams/partial_lfsr.bin > /dev/icap0");
  }

  return ret;
}

//------------------------------------------------------------------------------
// Set value of register reg in slot slot to value
//------------------------------------------------------------------------------
void prblock_set(int slot, unsigned int reg, uint32_t value)
{
	mbox_put(&mb_in[slot], reg);
	mbox_put(&mb_in[slot], value);
}

//------------------------------------------------------------------------------
// Returns current value of register reg of slot slot
//------------------------------------------------------------------------------
int prblock_get(int slot, unsigned int reg)
{
  unsigned int ret;

	mbox_put(&mb_in[slot], reg | 0x80000000);

	ret = mbox_get(&mb_out[slot]);

  printf("In slot %d, register %X has value %08X\n", slot, reg, ret);

	return ret;
}


uint32_t g_prblock_mem[PRBLOCK_MEM_SIZE];
//------------------------------------------------------------------------------
// Set memory of hardware_thread slot to a certain value
// All words are set to the same value
//------------------------------------------------------------------------------
int prblock_mem_set(int slot, uint32_t value)
{
#ifndef DO_MEMTEST
  return 0;
#endif

  if(slot == 0 || slot >= NUM_SLOTS) {
    printf("Slot %d does not contain a reconfigurable module\n", slot);
    return 0;
  }

  uint32_t* mem = g_prblock_mem;

  unsigned int i;
  for(i = 0; i < PRBLOCK_MEM_SIZE; i++)
    mem[i] = value;

  // flush the cache to ensure that valid data lies in the main memory
  reconos_cache_flush();

	mbox_put(&mb_in[slot], ((unsigned int)mem) | 0xC0000000);

  // copy has finished
	mbox_get(&mb_out[slot]);

	return 0;
}

//------------------------------------------------------------------------------
// Checks the current value of the memory in hardware_thread slot
// Returns 1 if the memory content matches value, 0 otherwise
//------------------------------------------------------------------------------
int prblock_mem_get(int slot, uint32_t value)
{
#ifndef DO_MEMTEST
  return 0;
#endif
  if(slot == 0 || slot >= NUM_SLOTS) {
    printf("Slot %d does not contain a reconfigurable module\n", slot);
    return 0;
  }

  uint32_t* mem = g_prblock_mem;

  // set to different value
  unsigned int i;
  for(i = 0; i < PRBLOCK_MEM_SIZE; i++)
    mem[i] = 0x00000000;

  // flush our local cache, otherwise the values we get are probably invalid
  reconos_cache_flush();

	mbox_put(&mb_in[slot], ((unsigned int)mem) | 0x40000000);

  // copy has finished
	mbox_get(&mb_out[slot]);

  // wait for potentially running transaction
  usleep(100);

  // check
  for(i = 0; i < PRBLOCK_MEM_SIZE; i++) {
    if(mem[i] != value) {
      printf("Memory contents different at index %d, expected %08X, actual %08X\n", i, value, mem[i]);
      return 0;
    }
  }

	return 1;
}

//------------------------------------------------------------------------------
// Simulates the LFSR that is implemented in hardware
// This function returns the value of the LFSR after iterations iterations,
// starting from state start
//------------------------------------------------------------------------------
unsigned int lfsr_sim(unsigned int iterations, unsigned int start) {
  unsigned int i;

  start = start & 0xFFFF;

  for(i = 0; i < iterations; i++) {
    unsigned int temp = (start << 1) & 0xFFFF;
    unsigned int bit10 = (start >> 10) & 0x1;
    unsigned int bit12 = (start >> 12) & 0x1;
    unsigned int bit13 = (start >> 13) & 0x1;
    unsigned int bit15 = (start >> 15) & 0x1;

    start = temp | (bit15 ^ bit13 ^ bit12 ^ bit10);
  }
  
  return start;
}

//------------------------------------------------------------------------------
// This function tests the add/sub block
// It returns 1 if the test was successful, 0 otherwise
//------------------------------------------------------------------------------
int prblock_test_add_sub(int slot, int thread_id)
{
  if(slot != HWT_DPR) {
    printf("Wrong slot, expected %d, got %d\n", HWT_DPR, slot);
    return 0;
  }

  unsigned int ret;
  prblock_set(slot, 0, 0x01003344);
  prblock_set(slot, 1, 0x01001122);

  // get result from register 2
  ret = prblock_get(slot, 2);

  // get counter value from register 3
  prblock_get(slot, 3);
  
  switch(thread_id) {
  case ADD:
    if (ret==(0x01003344)+(0x01001122)) {
      printf("  # ADD: passed\n");
    } else {
      printf("  # ADD: failed\n");
      return 0;
    }
    break;

  case SUB:
    if (ret==(0x01003344)-(0x01001122)) {
      printf("  # SUB: passed\n");
    } else {
      printf("  # SUB: failed\n");
      return 0;
    }
    break;

  default:
    printf("Unknown thread_id %d\n", thread_id);
    return 0;
  }

	return 1;
}

//------------------------------------------------------------------------------
// This function tests the MUL/LFSR block
// It returns 1 if the test was successful, 0 otherwise
//------------------------------------------------------------------------------
int prblock_test_mul_lfsr(int slot, int thread_id)
{
  if(slot != HWT_DPR2) {
    printf("Wrong slot, expected %d, got %d\n", HWT_DPR2, slot);
    return 0;
  }

  unsigned int ret;

  if(thread_id == MUL) {
    const unsigned int opA = 10;
    const unsigned int opB = 20;

    // test memory
    prblock_mem_set(slot, 0x11223344);

    if(prblock_mem_get(slot, 0x11223344) == 0)
      printf("  # PRBLOCK: memory failed\n");

    // set operands
    prblock_set(slot, 0, opA);
    prblock_set(slot, 1, opB);

    // start multiplier
    prblock_set(slot, 3, 0x00000001);

    ret = prblock_get(slot, 3);
    if(ret == 0) {
      ret = prblock_get(slot, 2);
      if(ret == opA * opB) {
        printf("Multiplier result is CORRECT\n");
      }
      else {
        printf("Multiplier result is wrong, expected %d, got %d\n", opA * opB, ret);
        return 0;
      }
    } else {
      printf("Multiplier too slow, still running\n");
      return 0;
    }
  } else if(thread_id == LFSR) {
    const unsigned int lfsr_num = 4;

    unsigned int i;
    for(i = 0; i < lfsr_num; i++) {
      prblock_set(slot, i + 1, 0x00000001);
    }

    // load them
    prblock_set(slot, 0, 0x00000001);

    // capture them
    prblock_set(slot, 0, 0x00000002);

    unsigned int iterations = prblock_get(slot, 0);

    ret = prblock_get(slot, 1);

    for(i = 1; i < lfsr_num; i++) {
      if( prblock_get(slot, i + 1) != ret) {
        printf("Results are not equal\n");
        return 0;
      }
    }

    if(ret != lfsr_sim(iterations, 0x1) ) {
      printf("LFSR is in wrong state\n");
      return 0;
    }

    printf("LFSR result correct!\n");
  } else {
    printf("Unsupported thread_id %d\n", thread_id);
  }

	return 1;
}

//------------------------------------------------------------------------------
// This function tests the PR blocks
// It returns 1 if the test was successful, 0 otherwise
//------------------------------------------------------------------------------
int prblock_test(int slot, int thread_id)
{
  if(slot == 0 || slot >= NUM_SLOTS) {
    printf("Slot %d does not contain a reconfigurable module\n", slot);
    return 0;
  }

  if(slot == 1)
    return prblock_test_add_sub(slot, thread_id);
  else
    return prblock_test_mul_lfsr(slot, thread_id);
}

//------------------------------------------------------------------------------
// Reconfigure the PR block contained in slot slot to the thread with id
// thread_id
//------------------------------------------------------------------------------
int prblock_reconfigure(int slot, int thread_id)
{
	timing_t t_start, t_stop;
  us_t t_check;

	int ret = -2;

	// send thread exit command
	mbox_put(&mb_in[slot],THREAD_EXIT_CMD);
  usleep(100);

  reconos_slot_reset(slot, 1);
  clock_enable(slot, 0);

  printf("Starting reconfiguration\n");
  fflush(stdout);

	t_start = gettime();
	
	// reconfigure hardware slot
  switch(g_arguments.reconf_mode) {
    case RECONF_LINUX:
      ret = linux_icap_load(slot, thread_id);
      break;
    case RECONF_SW:
      ret = sw_icap_load(slot, thread_id);
      break;
    case RECONF_HW:
      ret = hw_icap_load(slot, thread_id);
      break;
    default:
      break;
  }


	t_stop = gettime();
	t_check = calc_timediff_us(t_start, t_stop);

  printf("Reconfiguration done in %lu us, resetting hardware thread\n", t_check);

	// reset hardware thread
  clock_enable(slot, 1);
  reconos_slot_reset(slot,0);
  usleep(100);

	return ret;
}

//------------------------------------------------------------------------------
// Prepare a bitstream for capturing
//------------------------------------------------------------------------------
void prblock_capture_prepare(int slot, int thread_id, struct pr_capture_t* stream)
{
  bitstream_capture_prepare(&pr_bit[slot][thread_id], stream);
}

//------------------------------------------------------------------------------
// capture a prblock
//------------------------------------------------------------------------------
void prblock_capture(int slot, struct pr_capture_t* stream)
{
  // disable clock
  clock_enable(slot, 0);

  // wait some time to ensure that clock is really started
  // since the control is given to Linux this delays execution quite a bit and
  // destroys measurements
  //usleep(100);

  bitstream_capture_exec(stream);

  // enable clock
  clock_enable(slot, 1);

  // wait some time to ensure that clock is really started
  // since the control is given to Linux this delays execution quite a bit and
  // destroys measurements
  //usleep(100);
}

//------------------------------------------------------------------------------
// Free allocated memory
//------------------------------------------------------------------------------
void prblock_capture_free(struct pr_capture_t* stream)
{
  free(stream->block);
  free(stream->frames);
}


//------------------------------------------------------------------------------
// restore a previously captured PR block
//------------------------------------------------------------------------------
void prblock_restore(int slot, struct pr_capture_t* stream)
{
  // reset hardware thread, also disables FSLs
  // this is needed as otherwise invalid stuff gets written into the FIFOs and FSLs
  reconos_slot_reset(slot, 1);

  // stop clock
  clock_enable(slot, 0);

  // bitstream_restore would also do a grestore which we do manually afterwards
  //bitstream_restore(stream);
  hw_icap_write(stream->block, stream->length * 4);

  // start hardware thread again, releasing reset
  reconos_slot_reset(slot, 0);

  // now restore the previous information
  // This part would be timing critical if the clock was not stopped
  // grestore does not work anyway, so just use GSR
  // hw_icap_grestore();
  hw_icap_gsr();

  // start clock
  clock_enable(slot, 1);

  // wait some time to ensure that clock is really started
  // since the control is given to Linux this delays execution quite a bit and
  // destroys measurements
  //usleep(100);
}


//------------------------------------------------------------------------------
void segfault_sigaction(int signal, siginfo_t *si, void *arg)
{
  perror("segfault\n");
  printf("Caught segfault at address %p\n", si->si_addr);
  exit(0);
}

//------------------------------------------------------------------------------
void sigill_sigaction(int signal, siginfo_t *si, void *arg)
{
  perror("sigill\n");
  printf("Caught sigill at address %p\n", si->si_addr);
  exit(0);
}

//----------------------------------------------------------------------------//
//                                 MAIN                                       //
//----------------------------------------------------------------------------//
int main(int argc, char *argv[])
{
	unsigned cnt=1;
  unsigned int i;

	printf( "-------------------------------------------------------\n"
		    "ICAP DEMONSTRATOR\n"
		    "(" __FILE__ ")\n"
		    "Compiled on " __DATE__ ", " __TIME__ ".\n"
		    "-------------------------------------------------------\n\n" );

  //----------------------------------------------------------------------------
  // catch segfaults and invalid instructions
  // They should actually not happen, but if they do, we want to know as much
  // as possible about them
  //----------------------------------------------------------------------------
  // catch segmentation faults
  struct sigaction sa;

  memset(&sa, 0, sizeof(struct sigaction));
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = segfault_sigaction;
  sa.sa_flags     = SA_SIGINFO;

  sigaction(SIGSEGV, &sa, NULL);

  // catch SIGILLs
  struct sigaction sigill;

  memset(&sigill, 0, sizeof(struct sigaction));
  sigemptyset(&sigill.sa_mask);
  sigill.sa_sigaction = sigill_sigaction;
  sigill.sa_flags     = SA_ONSTACK | SA_RESTART | SA_SIGINFO;

  sigaction(SIGILL, &sigill, NULL);



  //----------------------------------------------------------------------------
  // command line parsing
  //----------------------------------------------------------------------------
  cmd_parsing(argc, argv, &g_arguments);
     

  //----------------------------------------------------------------------------
  // Initialize ReconOS
  //----------------------------------------------------------------------------
	printf("[icap_demo] Initialize ReconOS.\n");
	reconos_init_autodetect();

	printf("[icap_demo] Creating delegate threads.\n\n");
	for (i=0; i<NUM_SLOTS; i++){
		// mbox init
		mbox_init(&mb_in[i],  10);
    mbox_init(&mb_out[i], 10);
		// define resources
		res[i][0].type = RECONOS_TYPE_MBOX;
		res[i][0].ptr  = &mb_in[i];	  	
    res[i][1].type = RECONOS_TYPE_MBOX;
		res[i][1].ptr  = &mb_out[i];
		// start delegate threads
		reconos_hwt_setresources(&hwt[i],res[i],2);
		reconos_hwt_create(&hwt[i],i,NULL);
	}


  //----------------------------------------------------------------------------
  // cache partial bitstreams in memory
  //----------------------------------------------------------------------------
  bitstream_open("partial_bitstreams/partial_add.bin", &pr_bit[HWT_DPR][ADD]);
  bitstream_open("partial_bitstreams/partial_sub.bin", &pr_bit[HWT_DPR][SUB]);

  if(NUM_SLOTS > 2) {
    bitstream_open("partial_bitstreams/partial_mul.bin", &pr_bit[HWT_DPR2][MUL]);
    bitstream_open("partial_bitstreams/partial_lfsr.bin", &pr_bit[HWT_DPR2][LFSR]);
  }

  //----------------------------------------------------------------------------
  // print current register values
  //----------------------------------------------------------------------------
  prblock_get(HWT_DPR, 0);
  prblock_get(HWT_DPR, 1);
  prblock_get(HWT_DPR, 2);
  prblock_get(HWT_DPR, 3);

  if(NUM_SLOTS > 2) {
    prblock_get(HWT_DPR2, 0);
    prblock_get(HWT_DPR2, 1);
    prblock_get(HWT_DPR2, 2);
    prblock_get(HWT_DPR2, 3);
  }

  //----------------------------------------------------------------------------
  // what configuration mode are we using?
  //----------------------------------------------------------------------------
  switch(g_arguments.reconf_mode) {
    case RECONF_LINUX:
      printf("Using linux reconfiguration mode\n");
      break;
    case RECONF_SW:
      printf("Using software reconfiguration mode\n");
      break;
    case RECONF_HW:
      printf("Using hw reconfiguration mode\n");
      break;
    case RECONF_NULL:
      printf("Using null reconfiguration mode\n");
      break;
  }

  //----------------------------------------------------------------------------
  int slot = g_arguments.slot;
  struct pr_capture_t capture_add, capture_mul, capture_lfsr;
  const unsigned int opA = 0x112300AB;
  const unsigned int opB = 0x00A0B0C0;
  const unsigned int lfsr_num = 4;

  switch(g_arguments.mode) {
  //----------------------------------------------------------------------------
  case MODE_WRITE:
    while(1) {
      // reconfigure partial hw slot and check thread
      printf("[icap] Test no. %03d\n",cnt);

      prblock_reconfigure(HWT_DPR, ADD);
      prblock_test(HWT_DPR, ADD);

      // test memory
      prblock_mem_set(HWT_DPR, 0x11223344);

      if(prblock_mem_get(HWT_DPR, 0x11223344) == 0)
        printf("  # PRBLOCK: memory failed\n");

      if(NUM_SLOTS > 2) {
        prblock_reconfigure(HWT_DPR2, MUL);
        prblock_test(HWT_DPR2, MUL);

        // test memory
        prblock_mem_set(HWT_DPR2, 0x11223344);

        if(prblock_mem_get(HWT_DPR2, 0x11223344) == 0)
          printf("  # PRBLOCK: memory failed\n");
      }


      prblock_reconfigure(HWT_DPR, SUB);
      prblock_test(HWT_DPR, SUB);

      // test memory
      prblock_mem_set(HWT_DPR, 0xAABBCCDD);

      if(prblock_mem_get(HWT_DPR, 0xAABBCCDD) == 0)
        printf("  # PRBLOCK: memory failed\n");

      if(NUM_SLOTS > 2) {
        prblock_reconfigure(HWT_DPR2, LFSR);
        prblock_test(HWT_DPR2, LFSR);
      }

      // stop after n reconfigurations
      if(cnt == g_arguments.max_cnt)
        break;

      sleep(1); 
      cnt++;
    }

    break;

  //----------------------------------------------------------------------------
  case MODE_WRITE_ADD:
    prblock_reconfigure(HWT_DPR, ADD);
    prblock_test(HWT_DPR, ADD);

    // test memory
    prblock_mem_set(HWT_DPR, 0x11223344);

    if(prblock_mem_get(HWT_DPR, 0x11223344) == 0)
      printf("  # PRBLOCK: memory failed\n");

    break;

  //----------------------------------------------------------------------------
  case MODE_WRITE_SUB:
    prblock_reconfigure(HWT_DPR, SUB);
    prblock_test(HWT_DPR, SUB);

    // test memory
    prblock_mem_set(HWT_DPR, 0x11223344);

    if(prblock_mem_get(HWT_DPR, 0x11223344) == 0)
      printf("  # PRBLOCK: memory failed\n");

    break;

  //----------------------------------------------------------------------------
  case MODE_WRITE_MUL:
    prblock_reconfigure(HWT_DPR2, MUL);
    prblock_test(HWT_DPR2, MUL);
    
    // test memory
    prblock_mem_set(HWT_DPR2, 0xAABBCCDD);

    if(prblock_mem_get(HWT_DPR2, 0xAABBCCDD) == 0)
      printf("  # PRBLOCK: memory failed\n");
    break;

  //----------------------------------------------------------------------------
  case MODE_WRITE_LFSR:
    prblock_reconfigure(HWT_DPR2, LFSR);
    prblock_test(HWT_DPR2, LFSR);

    break;

  //----------------------------------------------------------------------------
  case MODE_CAPTURE:
    printf("Performing gcapture\n");
    hw_icap_gcapture();
    printf("GCAPTURE done\n");

    break;

  //----------------------------------------------------------------------------
  case MODE_RESTORE:
    printf("Performing GRESTORE\n");
    hw_icap_grestore();
    printf("GRESTORE done\n");

    break;

  //----------------------------------------------------------------------------
  // Load RM, set some values, capture it
  // Then set different values, load different RM
  // Finally restore original RM, check if values are identical
  //----------------------------------------------------------------------------
  case MODE_TEST_ADD:
    slot = HWT_DPR;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, ADD);
    prblock_test(slot, ADD);
    prblock_get(slot, 3);

    // set values that we want to capture
    prblock_set(slot, 3, 0x11223344);
    prblock_get(slot, 3);

    prblock_mem_set(slot, 0xAABBCCDD);
    prblock_mem_get(slot, 0xAABBCCDD);


    // capture bitstream
    prblock_capture_prepare(slot, ADD, &capture_add);
    prblock_capture(slot, &capture_add);

    printf("Capturing current state completed\n");
    fflush(stdout);

    // set it to a different value (just because)
    prblock_set(slot, 3, 0x00DD0000);
    prblock_test(slot, ADD);

    printf("Last check before reconfiguration\n");
    fflush(stdout);

    prblock_mem_set(slot, 0x01010101);
    prblock_mem_get(slot, 0x01010101);

    printf("Memory access done\n");
    fflush(stdout);
    prblock_get(slot, 3);

    printf("Configure sub module\n");
    fflush(stdout);

    // configure different module to erase all traces of the former
    prblock_reconfigure(slot, SUB);
    prblock_test(slot, SUB);

    printf("Restoring last state\n");
    fflush(stdout);

    // restore captured module
    prblock_restore(slot, &capture_add);

    printf("reset done\n");
    fflush(stdout);

    if( prblock_mem_get(slot, 0xAABBCCDD) == 0) {
      printf("### Memory test has failed\n");
    } else {
      printf("### Memory test OK\n");
    }

    if( prblock_get(slot, 3) == 0x11223344) {
      printf("### Captured value OK\n");
    } else {
      printf("### Captured value was wrong\n");
    }

    prblock_test(slot, ADD);

    prblock_capture_free(&capture_add);

    break;

  //----------------------------------------------------------------------------
  case MODE_READ:
    printf("Readback mode, reading %d words from 0x%08X\n", g_arguments.read_words, g_arguments.read_far);

    uint32_t* mem = (uint32_t*) malloc(g_arguments.read_words * sizeof(uint32_t));
    if(mem == NULL) {
      printf("Could not allocate memory\n");
      return EXIT_FAILURE;
    }

    hw_icap_read_frame(g_arguments.read_far, g_arguments.read_words, mem);

    for(i = 0; i < g_arguments.read_words; i++) {
      printf("%08X\n", mem[i]);
    }

    break;

  //----------------------------------------------------------------------------
  case MODE_SWITCH_BOT:
    icap_switch_bot();

    break;

  //----------------------------------------------------------------------------
  case MODE_SWITCH_TOP:
    icap_switch_top();
    
    break;

  //----------------------------------------------------------------------------
  case MODE_TEST2:
    slot = HWT_DPR;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, ADD);
    prblock_test(slot, ADD);
    prblock_set(slot, 3, 0);


    // capture bitstream
    prblock_capture_prepare(slot, ADD, &capture_add);

    hw_icap_gcapture();

    uint32_t* first_ff = (uint32_t*)malloc(capture_add.frames[1].words * sizeof(uint32_t));
    uint32_t* second_ff = (uint32_t*)malloc(capture_add.frames[1].words * sizeof(uint32_t));

    hw_icap_read_frame(capture_add.frames[1].far, capture_add.frames[1].words, first_ff);

    prblock_set(slot, 3, 1);
    hw_icap_gcapture();

    hw_icap_read_frame(capture_add.frames[1].far, capture_add.frames[1].words, second_ff);

    for(i = 0; i < capture_add.frames[1].words; i++) {
      if(first_ff[i] != second_ff[i])
        printf("Different %08X vs. %08X\n", first_ff[i], second_ff[i]);
    }

    printf("Done\n");


    break;

  //----------------------------------------------------------------------------
  // Together with TEST2 this tests if gcapture operates only on the region
  // selected by CFG_CLB. It does.
  //----------------------------------------------------------------------------
  case MODE_TEST3:
    slot = HWT_DPR;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, ADD);
    prblock_test(slot, ADD);
    prblock_set(slot, 3, 0);


    // capture bitstream
    prblock_capture_prepare(slot, ADD, &capture_add);

    hw_icap_gcapture();

    first_ff = (uint32_t*)malloc(capture_add.frames[1].words * sizeof(uint32_t));
    second_ff = (uint32_t*)malloc(capture_add.frames[1].words * sizeof(uint32_t));

    hw_icap_read_frame(capture_add.frames[1].far, capture_add.frames[1].words, first_ff);

    // ensure that CFG_CLB is overwritten
    prblock_reconfigure(HWT_DPR2, LFSR);
    prblock_test(HWT_DPR2, LFSR);

    prblock_set(slot, 3, 1);
    hw_icap_gcapture();

    hw_icap_read_frame(capture_add.frames[1].far, capture_add.frames[1].words, second_ff);

    for(i = 0; i < capture_add.frames[1].words; i++) {
      if(first_ff[i] != second_ff[i])
        printf("Different %08X vs. %08X\n", first_ff[i], second_ff[i]);
    }

    printf("Done\n");

    break;

  //----------------------------------------------------------------------------
  // Tests if block RAM needs GCAPTURE
  // Apparently it does not
  //----------------------------------------------------------------------------
  case MODE_TEST4:
    slot = HWT_DPR;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, ADD);
    prblock_test(slot, ADD);
    prblock_set(slot, 3, 0);
    prblock_mem_set(slot, 0x00000000);


    // capture bitstream
    prblock_capture_prepare(slot, ADD, &capture_add);

    hw_icap_gcapture();

    first_ff = (uint32_t*)malloc(capture_add.frames[2].words * sizeof(uint32_t));
    second_ff = (uint32_t*)malloc(capture_add.frames[2].words * sizeof(uint32_t));

    hw_icap_read_frame(capture_add.frames[2].far, capture_add.frames[2].words, first_ff);

    prblock_mem_set(slot, 0x00000001);
    //hw_icap_gcapture();

    hw_icap_read_frame(capture_add.frames[2].far, capture_add.frames[2].words, second_ff);

    for(i = 0; i < capture_add.frames[2].words; i++) {
      if(first_ff[i] != second_ff[i])
        printf("Different %08X vs. %08X\n", first_ff[i], second_ff[i]);
    }

    printf("Done\n");

    break;

  //----------------------------------------------------------------------------
  // Tests if block RAM needs GCAPTURE
  // Apparently it does not
  //----------------------------------------------------------------------------
  case MODE_READBACK_SPEED:
    slot = HWT_DPR;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, ADD);
    prblock_test(slot, ADD);


    // capture bitstream
    prblock_capture_prepare(slot, ADD, &capture_add);

    hw_icap_gcapture();


    for(i = 1; i < capture_add.nFrames; i++) {
      uint32_t* mem = (uint32_t*)malloc(capture_add.frames[i].words * sizeof(uint32_t));

      // do readback
      hw_icap_read_frame(capture_add.frames[i].far, capture_add.frames[i].words, mem);

      free(mem);
    }

    printf("Done\n");

    break;


  //----------------------------------------------------------------------------
  // Load RM, set some values, capture it
  // Then set different values, load different RM
  // Finally restore original RM, check if values are identical
  //----------------------------------------------------------------------------
  case MODE_TEST_MUL:
    slot = HWT_DPR2;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, MUL);
    prblock_test(slot, MUL);
    prblock_get(slot, 3);

    // set values that we want to capture
    printf("Set capture values\n");
    fflush(stdout);
    prblock_set(slot, 0, opA);
    prblock_set(slot, 1, opB);
    prblock_set(slot, 3, 0x00000001); // start multiplier

    printf("Set capture memory values\n");
    fflush(stdout);
    prblock_mem_set(slot, 0xAABBCCDD);
    printf("Check capture memory values\n");
    fflush(stdout);
    prblock_mem_get(slot, 0xAABBCCDD);


    // capture bitstream
    prblock_capture_prepare(slot, MUL, &capture_mul);
    prblock_capture(slot, &capture_mul);


    // set it to a different value (just because)
    // this destroys the currently running multiplier result
    prblock_set(slot, 0, 0x66666666);
    prblock_set(slot, 1, 0x66666666);
    prblock_set(slot, 2, 0x66666666);

    printf("Last check before reconfiguration\n");
    fflush(stdout);

    prblock_mem_set(slot, 0x01010101);
    prblock_mem_get(slot, 0x01010101);

    printf("Memory access done\n");
    fflush(stdout);

    printf("Configure LFSR module\n");
    fflush(stdout);

    // configure different module to erase all traces of the former
    prblock_reconfigure(slot, LFSR);
    prblock_test(slot, LFSR);

    printf("Restoring captured state\n");
    fflush(stdout);

    // restore captured module
    prblock_restore(slot, &capture_mul);

    printf("Restore done\n");
    fflush(stdout);

    if( prblock_mem_get(slot, 0xAABBCCDD) == 0) {
      printf("### ERROR: Memory test has failed\n");
    } else {
      printf("### Memory test OK\n");
    }

    // now check the multiplier result, wait for it to finish
    while(1) {
      sleep(1);

      if( prblock_get(slot, 3) == 0)
        break;
    }

    if( prblock_get(slot, 2) != opA * opB) {
      printf("### ERROR: Result is not correct. Expected %d, got %d\n", opA * opB, prblock_get(slot, 2));
    } else {
      printf("### Result is CORRECT\n");
    }

    prblock_capture_free(&capture_mul);

    break;

  //----------------------------------------------------------------------------
  // Load RM, set some values, capture it
  // Then set different values, load different RM
  // Finally restore original RM, check if values are identical
  //----------------------------------------------------------------------------
  case MODE_TEST_LFSR:
    slot = HWT_DPR2;

    // ensure that we are in a valid state first
    prblock_reconfigure(slot, LFSR);
    prblock_test(slot, LFSR);

    // set values that we want to capture
    for(i = 0; i < lfsr_num; i++) {
      prblock_set(slot, i + 1, 0x00000001);
    }

    // load them
    prblock_set(slot, 0, 0x00000001);


    // capture bitstream
    prblock_capture_prepare(slot, LFSR, &capture_lfsr);
    prblock_capture(slot, &capture_lfsr);

    printf("Capturing current state completed\n");
    fflush(stdout);


    // set it to a different value (just because)
    prblock_set(slot, 0, 0x66666666);
    prblock_set(slot, 1, 0x66666666);
    prblock_set(slot, 2, 0x66666666);

    prblock_get(slot, 1);

    printf("Poisoning current values in FPGA done\n");
    fflush(stdout);

    printf("Configure MUL module\n");
    fflush(stdout);

    // configure different module to erase all traces of the former
    prblock_reconfigure(slot, MUL);
    printf("Start test\n");
    fflush(stdout);
    prblock_test(slot, MUL);

    printf("Restoring captured PR block\n");
    fflush(stdout);

    // restore captured module
    prblock_restore(slot, &capture_lfsr);

    printf("Restore done\n");
    fflush(stdout);

    // now check the LFSR
    // capture them
    prblock_set(slot, 0, 0x00000002);

    unsigned int iterations = prblock_get(slot, 0);

    unsigned int lfsr_value = prblock_get(slot, 1);

    for(i = 1; i < lfsr_num; i++) {
      if( prblock_get(slot, i + 1) != lfsr_value) {
        printf("### ERROR: Results are not equal\n");
      }
    }

    unsigned int lfsr_value_sim = lfsr_sim(iterations, 0x1);
    if(lfsr_value != lfsr_value_sim ) {
      printf("### ERROR: LFSR is in wrong state, should be %X\n", lfsr_value_sim);
    } else {
      printf("### LFSR correct: %X\n", lfsr_value);
    }

    prblock_capture_free(&capture_lfsr);

    break;

  //----------------------------------------------------------------------------
  // Continuously swap two reconfigurable blocks
  //----------------------------------------------------------------------------
  case MODE_TEST_SWAP:
    slot = HWT_DPR2;

    //--------------------------------------------------------------------------
    // Prepare LFSR module for capturing
    //--------------------------------------------------------------------------
    printf("Configure LFSR module\n");
    fflush(stdout);
    // ensure that we are in a valid state first
    prblock_reconfigure(slot, LFSR);
    prblock_test(slot, LFSR);

    // set values that we want to capture

    for(i = 0; i < lfsr_num; i++) {
      prblock_set(slot, i + 1, 0x00000001);
    }

    // load them
    prblock_set(slot, 0, 0x00000001);


    // capture bitstream
    prblock_capture_prepare(slot, LFSR, &capture_lfsr);
    prblock_capture(slot, &capture_lfsr);

    printf("Capturing current state completed\n");
    fflush(stdout);


    //--------------------------------------------------------------------------
    // Prepare MUL module for capturing
    //--------------------------------------------------------------------------
    printf("Configure MUL module\n");
    fflush(stdout);

    prblock_reconfigure(slot, MUL);
    prblock_test(slot, MUL);

    // set memory
    prblock_mem_set(slot, 0xAABBCCDD);

    // set values that we want to capture
    prblock_set(slot, 0, opA);
    prblock_set(slot, 1, opB);
    prblock_set(slot, 3, 0x00000001); // start multiplier

    // capture bitstream
    prblock_capture_prepare(slot, MUL, &capture_mul);
    prblock_capture(slot, &capture_mul);

    printf("Capturing current state completed\n");
    fflush(stdout);


    //--------------------------------------------------------------------------
    // Now enter the main loop and swap those modules
    //--------------------------------------------------------------------------
    for(cnt = 0; cnt < g_arguments.max_cnt; cnt++) {
      printf("Swap Round %d\n", cnt + 1);

      //------------------------------------------------------------------------
      // LFSR
      //------------------------------------------------------------------------
      printf("LFSR: Restoring captured PR block\n");
      fflush(stdout);

      // restore captured module
      prblock_restore(slot, &capture_lfsr);

      printf("LFSR: Restore done\n");
      fflush(stdout);

      // now check the LFSR
      // capture them
      prblock_set(slot, 0, 0x00000002);

      unsigned int iterations = prblock_get(slot, 0);

      unsigned int lfsr_value = prblock_get(slot, 1);

      for(i = 1; i < lfsr_num; i++) {
        if( prblock_get(slot, i + 1) != lfsr_value) {
          printf("### ERROR: Results are not equal\n");
        }
      }

      unsigned int lfsr_value_sim = lfsr_sim(iterations, 0x1);
      if(lfsr_value != lfsr_value_sim ) {
        printf("### ERROR: LFSR is in wrong state, should be %X\n", lfsr_value_sim);
      } else {
        printf("### LFSR: correct: %X\n", lfsr_value);
      }



      // start timer
      fflush(stdout);
      timing_t t_start, t_capture, t_stop;
      us_t t_caprest, t_cap, t_rest;
      t_start = gettime();
	

      prblock_capture(slot, &capture_lfsr);

      t_capture = gettime();

      //------------------------------------------------------------------------
      // MUL
      //------------------------------------------------------------------------
      prblock_restore(slot, &capture_mul);

      // measure time
      t_stop = gettime();
      t_cap = calc_timediff_us(t_start, t_capture);
      t_caprest = calc_timediff_us(t_start, t_stop);
      t_rest = calc_timediff_us(t_capture, t_stop);
      printf("Capture and restore done in %6lu us, capture done in %6lu us, restore done in %6lu us\n", t_caprest, t_cap, t_rest);


      printf("MUL: Restore done\n");
      fflush(stdout);

      if( prblock_mem_get(slot, 0xAABBCCDD) == 0) {
        printf("### ERROR: Memory test has failed\n");
      } else {
        printf("### Memory test OK\n");
      }

      prblock_mem_set(slot, 0xAABBCCDD);

      // now check the multiplier result, wait for it to finish
      while(1) {
        sleep(1);

        if( prblock_get(slot, 3) == 0)
          break;
      }

      if( prblock_get(slot, 2) != opA * opB) {
        printf("### ERROR: Result is not correct. Expected %d, got %d\n", opA * opB, prblock_get(slot, 2));
      } else {
        printf("### MUL: CORRECT\n");
      }

      // start next iteration
      prblock_set(slot, 0, opA);
      prblock_set(slot, 1, opB);
      prblock_set(slot, 3, 0x00000001); // start multiplier

      prblock_capture(slot, &capture_mul);
    }

    prblock_capture_free(&capture_lfsr);
    prblock_capture_free(&capture_mul);

    break;

  //----------------------------------------------------------------------------
  default:
    printf("No argument supplied, doing nothing\n");
    break;
  }
  //----------------------------------------------------------------------------

  bitstream_close(&pr_bit[HWT_DPR][ADD]);
  bitstream_close(&pr_bit[HWT_DPR][SUB]);

  if(NUM_SLOTS > 2) {
    bitstream_close(&pr_bit[HWT_DPR2][MUL]);
    bitstream_close(&pr_bit[HWT_DPR2][LFSR]);
  }

  printf("Exiting now\n");

	return 0;
}

