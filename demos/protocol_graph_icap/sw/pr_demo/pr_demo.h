#ifndef ICAP_DEMO_H
#define ICAP_DEMO_H

// hw threads
#define NUM_SLOTS 5
//#define HWT_ICAP  0
//#define HWT_DPR   1

#define HWT_S2H 0  // hwt_s2h
#define HWT_H2S 1  // hwt_h2s
#define HWT_ETH 2  // hwt_ethernet_test
#define HWT_DPR 3  // dynamic partial reconfiguable (DPR) hwt
#define HWT_ICAP 4 // hw thread for ICAP

//#define ADD 0
//#define SUB 1
#define AES 0
#define IPS 1
#define NONE 0xFF

#define THREAD_EXIT_CMD 0xFFFFFFFF

extern struct reconos_resource res[NUM_SLOTS][2];
extern struct reconos_hwt hwt[NUM_SLOTS];
extern struct mbox mb_in[NUM_SLOTS];
extern struct mbox mb_out[NUM_SLOTS];


int cache_bitstream(int thread_id, const char* path);
int hw_icap_write(uint32_t* addr, unsigned int size);
int sw_icap_write(uint32_t* addr, unsigned int size);
int sw_icap_load(int thread_id);
int hw_icap_load(int thread_id);
int linux_icap_load(int thread_id);

void hwt_icap_switch_bot();


#endif
