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

// ReconOS
#include "reconos.h"
#include "mbox.h"
#include "timing.h"

#include "icap_demo.h"

//------------------------------------------------------------------------------
// load arbitrary cmd sequence via hardware icap thread
// size must be in bytes
//------------------------------------------------------------------------------
int hw_icap_write(uint32_t* addr, unsigned int size)
{
	int ret;
  if(((unsigned int)addr % 4) != 0 || (size % 4) != 0) {
    printf("hw_icap_write: Addr or size not word aligned! Addr %08X, Size %08X\n", (unsigned int)addr, size);
    return 0;
  }

  // send address of bitfile in main memory to hwt
	mbox_put(&mb_in[HWT_ICAP], (unsigned int)addr);

  // send length of bitfile (in bytes) in main memory to hwt
	mbox_put(&mb_in[HWT_ICAP], size);

  // wait for response from hwt
	ret = mbox_get(&mb_out[HWT_ICAP]);
  if(ret != 0x1337) {
    printf("hwt_icap returned ERROR, code %X\n", ret);
    return 0;
  }

	return 1;
}

//------------------------------------------------------------------------------
// Reads from the ICAP interface. This only works if a readback has been
// initiated manually before, otherwise this will block and never return
// size must be in bytes
//------------------------------------------------------------------------------
int hw_icap_read(uint32_t* addr, unsigned int size)
{
	int ret;
  if(((unsigned int)addr % 4) != 0 || (size % 4) != 0) {
    printf("hw_icap_read: Addr or size not word aligned! Addr %08X, Size %08X\n", (unsigned int)addr, size);
    return 0;
  }

  // send address of bitfile in main memory to hwt
	mbox_put(&mb_in[HWT_ICAP], (unsigned int)addr);

  // send length of bitfile (in bytes) in main memory to hwt
	mbox_put(&mb_in[HWT_ICAP], size | 0x00000001);

  // wait for response from hwt
	ret = mbox_get(&mb_out[HWT_ICAP]);
  if(ret != 0x1337) {
    printf("hwt_icap returned ERROR, code %X\n", ret);
    return 0;
  }

	return 1;
}

//------------------------------------------------------------------------------
// load arbitrary cmd sequence via software icap
// size must be in bytes
//------------------------------------------------------------------------------
int sw_icap_write(uint32_t* addr, unsigned int size)
{
  int retval = 0;

  int fd = open("/dev/icap0", O_WRONLY);
  if(fd == -1) {
    printf("sw_icap_write: Could not open icap\n");

    goto FAIL;
  }

  // write whole file in one command
  if( write(fd, addr, size) != size ) {
    printf("sw_icap_write: Something went wrong while writing to ICAP\n");

    goto FAIL;
  }

  retval = 1;

FAIL:
  if(fd != -1)
    close(fd);

  return retval;
}


// icap switch to bottom
uint32_t g_icap_switch_bot[] = {0xFFFFFFFF, // Dummy word
                                0x000000BB, // Bus Width Sync Word
                                0x11220044, // Bus Width Detect
                                0xFFFFFFFF, // Dummy Word
                                0xAA995566, // SYNC
                                0x20000000, // NOOP
                                0x3000A001, // write to mask
                                0x40000000, // icap control
                                0x20000000, // NOOP
                                0x3000C001, // write to ctl0
                                0x40000000, // change icap
                                0x20000000, // NOOP
                                0x30008001, // write to cmd
                                0x0000000D, // DESYNC
                                0x20000000, // NOOP
                                0x20000000}; // NOOP

// icap switch to top
uint32_t g_icap_switch_top[] = {0xFFFFFFFF, // Dummy word
                                0x000000BB, // Bus Width Sync Word
                                0x11220044, // Bus Width Detect
                                0xFFFFFFFF, // Dummy Word
                                0xAA995566, // SYNC
                                0x20000000, // NOOP
                                0x3000A001, // write to mask
                                0x40000000, // icap control
                                0x20000000, // NOOP
                                0x3000C001, // write to ctl0
                                0x00000000, // change icap
                                0x20000000, // NOOP
                                0x30008001, // write to cmd
                                0x0000000D, // desync
                                0x20000000, // NOOP
                                0x20000000}; // NOOP

//------------------------------------------------------------------------------
// switches to bottom icap using HWT_ICAP
//------------------------------------------------------------------------------
void icap_switch_bot() {
  // has to be done two times, don't know why?
  hw_icap_write(g_icap_switch_bot, sizeof g_icap_switch_bot);
  hw_icap_write(g_icap_switch_bot, sizeof g_icap_switch_bot);
}

//------------------------------------------------------------------------------
// should switch to top ICAP using XPS_HWICAP
// WARNING: Does not seem to work for some reason?
//------------------------------------------------------------------------------
void icap_switch_top() {
  sw_icap_write(g_icap_switch_top, sizeof g_icap_switch_top);
}


//------------------------------------------------------------------------------
// icap_read
//------------------------------------------------------------------------------
uint32_t g_icap_read_cmd[] = {0xFFFFFFFF,
                              0x000000BB,
                              0x11220044,
                              0xFFFFFFFF,
                              0xAA995566, // sync
                              0x20000000, // noop
                              0x30008001, // write to cmd
                              0x0000000B, // SHUTDOWN
                              0x20000000, // noop
                              0x30008001, // write to cmd
                              0x00000007, // RCRC
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x30008001, // write to cmd
                              0x00000004, // RCFG
                              0x20000000, // noop
                              0x30002001, // write to FAR
                              0x00008A80, // FAR address, will be replaced
                              0x28006000, // type 1 read 0 words from FDRO
                              0x48000080, // type 2 read 128 words from FDRO, will be replaced
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000, // noop
                              0x20000000};// noop

uint32_t g_icap_read_cmd2[] = {0x20000000, // noop
                               0x30008001, // write to cmd
                               0x00000005, // START
                               0x20000000, // noop
                               0x30008001, // write to cmd
                               0x00000007, // RCRC
                               0x20000000, // noop
                               0x30008001, // write to cmd
                               0x0000000D, // DESYNC
                               0x20000000, // noop
                               0x20000000};// noop

//------------------------------------------------------------------------------
// Reads a frame from ICAP given by the frame address far
// size must be in words
//------------------------------------------------------------------------------
int hw_icap_read_frame(uint32_t far, uint32_t size, uint32_t* dst)
{
  int ret;
  // account for the padframe and dummy words
  uint32_t real_size = size + 82;

  g_icap_read_cmd[21] = far;
  g_icap_read_cmd[23] = (real_size) | 0x48000000;


  ret = hw_icap_write(g_icap_read_cmd, sizeof g_icap_read_cmd);
  if(ret == 0) {
    printf("hw_icap_read_frame: Writing first command sequence to ICAP has failed\n");
    return 0;
  }
  
  // read
  uint32_t* mem = (uint32_t*)malloc(real_size * sizeof(uint32_t));
  if(mem == NULL) {
    printf("Could not allocate buffer\n");
    return 0;
  }

  memset(mem, 0xAB, real_size * sizeof(uint32_t));

  // AAARGH FUU ZOMFG RAGE!!!!
  // we need to flush the cache here as otherwise we get a part of old data and a part of new data
  reconos_cache_flush();


  // start timer
  usleep(100);
  fflush(stdout);
  timing_t t_start, t_stop;
  us_t t_check;
  t_start = gettime();
  // end start

  ret = hw_icap_read(mem, real_size * sizeof(uint32_t));
  if(ret == 0) {
    printf("hw_icap_read_frame: Reading from ICAP has failed\n");
    return 0;
  }

  // measure time
  t_stop = gettime();
  t_check = calc_timediff_us(t_start, t_stop);
  printf("Readback of FAR 0x%08X, %d words done in %lu us\n", far, size, t_check);
  // end measure

  ret = hw_icap_write(g_icap_read_cmd2, sizeof g_icap_read_cmd2);
  if(ret == 0) {
    printf("hw_icap_read_frame: Writing first command sequence to ICAP has failed\n");
    return 0;
  }

  // the first 82 words are rubish, because they are from the pad frame and a dummy word
  memcpy(dst, mem + 82, (size) * 4);

  free(mem);

  return 1;
}

//------------------------------------------------------------------------------
// icap_read_capture
//------------------------------------------------------------------------------
uint32_t g_icap_read_capture_cmd[] = {
  0xFFFFFFFF,
  0x000000BB,
  0x11220044,
  0xFFFFFFFF,
  0xAA995566, // sync
  0x20000000, // noop
  0x30008001, // write to cmd
  0x0000000B, // SHUTDOWN
  0x20000000, // noop
  0x30008001, // write to cmd
  0x00000007, // RCRC
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x30008001, // write to cmd
  0x0000000C, // gcapture
  0x20000000, // noop
  0x30002001, // write to FAR
  0x00000000, // FAR address
  0x20000000, // noop
  0x20000000, // noop
  0x30008001, // write to cmd
  0x00000004, // RCFG
  0x20000000, // noop
  0x30002001, // write to FAR
  0x00008A80, // FAR address, will be replaced
  0x28006000, // type 1 read 0 words from FDRO
  0x48000080, // type 2 read 128 words from FDRO, will be replaced
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000};// noop

uint32_t g_icap_read_multiple[] = {
  0x20000000, // noop
  0x30008001, // write to cmd
  0x00000007, // RCRC
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x30008001, // write to cmd
  0x00000004, // RCFG
  0x20000000, // noop
  0x30002001, // write to FAR
  0x00008A80, // FAR address
  0x28006000, // type 1 read 0 words from FDRO
  0x48000080, // type 2 read 128 words from FDRO
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000, // noop
  0x20000000};// noop


//------------------------------------------------------------------------------
// Read multiple frames in one command. This is useful for capturing a bitstream,
// as hopefully the hardware is stopped during readback. This has to be tested though
//------------------------------------------------------------------------------
uint32_t temp_mem[82];
int hw_icap_read_capture(struct pr_frame_t* frames, unsigned int num, uint32_t* block)
{
  int ret;

  if(num == 0)
    return 0;

  // prepare first frame for readback
  // account for the padframe and dummy words
  uint32_t real_size = frames[0].words + 82;

  g_icap_read_capture_cmd[28] = frames[0].far;
  g_icap_read_capture_cmd[30] = (real_size) | 0x48000000;

  ret = hw_icap_write(g_icap_read_capture_cmd, sizeof g_icap_read_capture_cmd);
  if(ret == 0) {
    printf("hw_icap_read_capture: Writing first command sequence to ICAP has failed\n");
    return 0;
  }

  unsigned int i;
  for(i = 0; i < num; i++) {
    // prepare the next frame for readback
    // the first frame is already ready as we have done that in the first write (see above)
    if(i != 0) {
      // account for the padframe and dummy words
      real_size = frames[i].words + 82;

      g_icap_read_multiple[13] = frames[i].far;
      g_icap_read_multiple[15] = (real_size) | 0x48000000;

      // prepare next frame for readback
      ret = hw_icap_write(g_icap_read_multiple, sizeof g_icap_read_multiple);
      if(ret == 0) {
        printf("hw_icap_read_capture: Writing first command sequence to ICAP has failed\n");
        return 0;
      }
    }

    // save the first 82 words, as we need them later
    memcpy(temp_mem, block + frames[i].offset - 82, 82 * sizeof(uint32_t));

    ret = hw_icap_read(block + frames[i].offset - 82, real_size * sizeof(uint32_t));
    if(ret == 0) {
      printf("hw_icap_read_capture: Reading from ICAP has failed\n");
      return 0;
    }


    // the first 82 words are rubish, because they are from the pad frame and a dummy word
    memcpy(block + frames[i].offset - 82, temp_mem, 82 * sizeof(uint32_t));
  }

  // we have finished reading, desync the ICAP interface
  ret = hw_icap_write(g_icap_read_cmd2, sizeof g_icap_read_cmd2);
  if(ret == 0) {
    printf("hw_icap_read_capture: Writing first command sequence to ICAP has failed\n");
    return 0;
  }

  // we need to flush the cache here as otherwise we get a part of old data and a part of new data
  reconos_cache_flush();

  return 1;
}

//------------------------------------------------------------------------------
// icap_gcapture
//------------------------------------------------------------------------------
uint32_t g_icap_gcapture[] = {0xFFFFFFFF,
                              0x000000BB,
                              0x11220044,
                              0xFFFFFFFF,
                              0xAA995566, // sync
                              0x20000000, // noop
                              0x20000000, // noop
                              0x30008001, // write to cmd
                              0x0000000C, // gcapture
                              0x20000000, // noop
                              0x30002001, // write to FAR
                              0x00000000, // FAR address
                              0x20000000, // noop
                              0x20000000, // noop
                              0x30008001, // write to cmd
                              0x0000000D, // DESYNC
                              0x20000000, // noop
                              0x20000000};// noop

int hw_icap_gcapture() {
  return hw_icap_write(g_icap_gcapture, sizeof g_icap_gcapture);
}

//------------------------------------------------------------------------------
// icap_grestore
//------------------------------------------------------------------------------
uint32_t g_icap_grestore[] = {
  0xFFFFFFFF,
  0x000000BB,
  0x11220044,
  0xFFFFFFFF,
  0xAA995566, // sync
  0x20000000, // noop
  0x20000000, // noop
  0x3000C001, // Type 1 packet, Write, MASK reg 1 packets follow
  0x00000400, // belongs to previous packet, 0 packets follow
  0x3000A001, // Type 1 packet, Write, CTL0 reg 1 packets follow
  0x00000400, // belongs to previous packet, 0 packets follow
  0x30008001, // Type 1 packet, Write, CMD reg 1 packets follow
  0x00000000, // NULL belongs to previous packet, 0 packets follow
  0x30002001, // Type 1 packet, Write, FAR reg 1 packets follow
  0x00000000, // belongs to previous packet, 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x30008001, //Type 1 packet, Write, CMD reg 1 packets follow
  0x0000000B, //SHUTDOWN belongs to previous packet, 0 packets follow
  0x20000000, //Type 1 packet, NOOP 0 packets follow
  0x20000000, //Type 1 packet, NOOP 0 packets follow
  0x20000000, //Type 1 packet, NOOP 0 packets follow
  0x20000000, //Type 1 packet, NOOP 0 packets follow
  0x20000000, //Type 1 packet, NOOP 0 packets follow
  0x30008001, //Type 1 packet, Write, CMD reg 1 packets follow
  0x00000000, //NULL belongs to previous packet, 0 packets follow
  0x30002001, //Type 1 packet, Write, FAR reg 1 packets follow
  0x00000000, // belongs to previous packet, 0 packets follow
  0x30008001, // Type 1 packet, Write, CMD reg 1 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x0000000A, // GRESTORE belongs to previous packet, 0 packets follow
  0x20000000};// Type 1 packet, NOOP 0 packets follow
uint32_t g_icap_grestore2[] = {
  0x3000C001, // Type 1 packet, Write, MASK reg 1 packets follow
  0x00001000, // belongs to previous packet, 0 packets follow
  0x30030001, // Type 1 packet, Write, unknown reg 1 packets follow
  0x00000000, // belongs to previous packet, 0 packets follow
  0x30008001, // Type 1 packet, Write, CMD reg 1 packets follow
  0x00000003, // DGHIGH belongs to previous packet, 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x30008001, // Type 1 packet, Write, CMD reg 1 packets follow
  0x00000005, // START belongs to previous packet, 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x30002001, // Type 1 packet, Write, FAR reg 1 packets follow
  0x00EF8000, // belongs to previous packet, 0 packets follow
  0x30008001, // Type 1 packet, Write, CMD reg 1 packets follow
  0x0000000D, // DESYNC belongs to previous packet, 0 packets follow DESYNCH
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000, // Type 1 packet, NOOP 0 packets follow
  0x20000000};// Type 1 packet, NOOP 0 packets follow


int hw_icap_grestore() {
  int ret;

  ret = hw_icap_write(g_icap_grestore, sizeof(g_icap_grestore));
  if(ret == 0) {
    printf("Writing first restore sequence failed\n");
  }

  // GRESTORE does not work for some unknown reason, but GSR on STARTUP_VIRTEX6 does,
  // so we are using GSR instead
  hw_icap_gsr();

  ret = hw_icap_write(g_icap_grestore2, sizeof(g_icap_grestore2));
  if(ret == 0) {
    printf("Writing second restore sequence failed\n");
  }

  return 1;
}

//------------------------------------------------------------------------------
// assert GSR for one cycle
// This is done by using STARTUP_VIRTEX6 on HWT_ICAP
//------------------------------------------------------------------------------
int hw_icap_gsr() {
	int ret;

  // send GSR command (bit 0 of address must be 1)
	mbox_put(&mb_in[HWT_ICAP], 0x1);

  // wait for response from hwt
	ret = mbox_get(&mb_out[HWT_ICAP]);
  if(ret != 0x1337) {
    printf("hwt_icap returned ERROR, code %X\n", ret);
    return 0;
  }

	return 1;
}

//------------------------------------------------------------------------------
// icap_write_frame
//------------------------------------------------------------------------------
uint32_t g_icap_write_frame[] = {0xFFFFFFFF,
                                 0x000000BB,
                                 0x11220044,
                                 0xFFFFFFFF,
                                 0xAA995566, // sync
                                 0x20000000, // noop
                                 0x30008001, // write to cmd
                                 0x00000007, // RCRC
                                 0x20000000, // noop
                                 0x20000000, // noop
                                 0x20000000, // noop
                                 0x20000000, // noop
                                 0x30008001, // write to cmd
                                 0x00000001, // WCFG
                                 0x20000000, // noop
                                 0x30002001, // write to far
                                 0x00400000, // FAR
                                 0x20000000, // noop
                                 0x30004000, // write to FDRI
                                 0x5000C756};// type 2 packet, nr of packets

uint32_t g_icap_write_frame2[] = {0x20000000, // 100 noops, don't know how many are really needed
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x20000000, // noop
                                  0x30008001, // write to cmd
                                  0x0000000D, // DESYNC
                                  0x20000000, // noop
                                  0x20000000};// noop



//------------------------------------------------------------------------------
// Write a frame to ICAP, given by the frame address far, number of words and 
// the buffer where the frame is stored (addr).
//------------------------------------------------------------------------------
int hw_icap_write_frame(uint32_t far, uint32_t* addr, unsigned int words)
{
	int ret;

  // set FAR and size
  g_icap_write_frame[11] = far;
  g_icap_write_frame[14] = words | 0x50000000;

  ret = hw_icap_write(g_icap_write_frame, sizeof g_icap_write_frame);
  if(ret == 0) {
    printf("hw_icap_write_frame: Write to ICAP has failed on first command sequence\n");
    return 0;
  }

  ret = hw_icap_write(addr, words * sizeof(uint32_t));
  if(ret == 0) {
    printf("hw_icap_write_frame: Write to ICAP has failed on actual frame\n");
    return 0;
  }

  ret = hw_icap_write(g_icap_write_frame2, sizeof g_icap_write_frame2);
  if(ret == 0) {
    printf("hw_icap_write_frame: Write to ICAP has failed on second command sequence\n");
    return 0;
  }

	return 1;
}

