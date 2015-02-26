#ifndef ICAP_DEMO_H
#define ICAP_DEMO_H

// hw threads
#define NUM_SLOTS 3
#define HWT_ICAP  0
#define HWT_DPR   1
#define HWT_DPR2  2

#define ADD 0
#define SUB 1

#define MUL  0
#define LFSR 1

#define DO_MEMTEST
#define PRBLOCK_MEM_SIZE  2048

#define THREAD_EXIT_CMD 0xFFFFFFFF

extern struct reconos_resource res[NUM_SLOTS][2];
extern struct reconos_hwt hwt[NUM_SLOTS];
extern struct mbox mb_in[NUM_SLOTS];
extern struct mbox mb_out[NUM_SLOTS];


struct pr_bitstream_t {
  uint32_t* block;
  unsigned int length; // in 32 bit words
};

struct pr_frame_t {
  uint32_t far;
  uint32_t offset; // offset from start in bitstream in words
  uint32_t words; // in words
};

struct pr_capture_t {
  uint32_t* block;
  unsigned int length; // in 32 bit words
  struct pr_frame_t* frames;
  unsigned int nFrames;
};

extern struct pr_bitstream_t pr_bit[NUM_SLOTS][2]; // the first one will not be used as it is not a reconfigurable module

int bitstream_open(const char* path, struct pr_bitstream_t* stream);
void bitstream_close(struct pr_bitstream_t* stream);
int bitstream_save(const char* path, struct pr_bitstream_t* stream);
int bitstream_capture_prepare(struct pr_bitstream_t* stream_in, struct pr_capture_t* stream_out);
int bitstream_capture_exec(struct pr_capture_t* stream);
int bitstream_restore(struct pr_capture_t* stream);


int hw_icap_write(uint32_t* addr, unsigned int size);
int hw_icap_read(uint32_t* addr, unsigned int size);
int hw_icap_read_frame(uint32_t far, uint32_t size, uint32_t* dst);
int hw_icap_read_capture(struct pr_frame_t* frames, unsigned int num, uint32_t* block);
int hw_icap_write_frame(uint32_t far, uint32_t* addr, unsigned int words);

int sw_icap_write(uint32_t* addr, unsigned int size);

int sw_icap_load(int slot, int thread_id);
int hw_icap_load(int slot, int thread_id);
int linux_icap_load(int slot, int thread_id);

void icap_switch_bot();
void icap_switch_top();

int hw_icap_gcapture();
int hw_icap_grestore();
int hw_icap_gsr();

int sw_icap_gcapture();
int sw_icap_grestore();

// command line parsing
#define RECONF_LINUX 0
#define RECONF_SW    1
#define RECONF_HW    2
#define RECONF_NULL  3

#define MODE_WRITE       0
#define MODE_READ        1
#define MODE_WRITE_ADD   2
#define MODE_WRITE_SUB   3
#define MODE_CAPTURE     4
#define MODE_RESTORE     5
#define MODE_TEST_ADD    6
#define MODE_SWITCH_BOT  7
#define MODE_TEST2       8
#define MODE_TEST3       9
#define MODE_SWITCH_TOP 10
#define MODE_WRITE_MUL  11
#define MODE_TEST_MUL   12
#define MODE_TEST_LFSR  13
#define MODE_WRITE_LFSR 14
#define MODE_TEST_SWAP  15
#define MODE_TEST4      16
#define MODE_READBACK_SPEED      17

struct cmd_arguments_t {
  unsigned int reconf_mode;
  unsigned int mode;
  unsigned int max_cnt;
  unsigned int read_far;
  unsigned int read_words;
  int slot;
};

void cmd_parsing(int argc, char* argv[], struct cmd_arguments_t* arguments);


#endif
