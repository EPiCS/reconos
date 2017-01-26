/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Markus Happe <markus.happe@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2013 Sebastian Meisner <sebastian.meisner@upb.de>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>

#include "reconos.h"
#include "fsl.h"
#include "mbox.h"
#include "rqueue.h"
#include "xutils.h"
#include "thread_shadowing.h"
#include "thread_shadowing_error_handler.h"
#include "thread_shadowing_subs.h"

static struct reconos_process reconos_proc;

void reconos_slot_reset(int num, int reset)
{
	int i;
	uint32_t cmd, mask = 0;
	
	if (reset)
		reconos_proc.slot_flags[num] |= SLOT_FLAG_RESET;
	else
		reconos_proc.slot_flags[num] &= ~SLOT_FLAG_RESET;
	
	for (i = SLOTS_MAX - 1; i >= 0; i--) {
		mask = mask << 1;
		if ((reconos_proc.slot_flags[i] & SLOT_FLAG_RESET))
			mask = mask | 1;
	}

	cmd = mask | 0x01000000;
	fsl_write(reconos_proc.proc_control_fsl_b, cmd);
}

static uint32_t reconos_getpgd(void)
{
	int res, fd;
	uint32_t pgd;

	fd = open_or_die("/dev/getpgd", O_RDONLY);

	res = read(fd, &pgd, sizeof(pgd));
	if (res != sizeof(pgd)){
		//panic("Read error from /dev/getpgd!\n");
		sh_file_readwrite_error_handler("/dev/getpgd",res, sizeof(pgd), 0,0 );
	}

	close(fd);
	return pgd;
}

void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
		       uint32_t *page_faults)
{
	uint32_t hits, misses;

	/* XXX: @aagne: can we make defines for 0x05000000 and co? ---DB */
	fsl_write(reconos_proc.proc_control_fsl_b, 0x05000000);

	hits = fsl_read(reconos_proc.proc_control_fsl_b);
	misses = fsl_read(reconos_proc.proc_control_fsl_b);

	if (page_faults)
		*page_faults = reconos_proc.page_faults;
	if (tlb_misses)
		*tlb_misses = misses;
	if (tlb_hits)
		*tlb_hits = hits;
}


#define CMD_FAULT_INJECTION 0xF0000000
void reconos_faultinject(uint8_t channel, uint32_t sa0, uint32_t sa1){
	whine("LIBRECONOS: Activating fault at channel %hhd and values 0x%lx, 0x%lx\n", channel, sa0, sa1);
	uint32_t cmd_n_channel = CMD_FAULT_INJECTION | channel;
	whine("LIBRECONOS: fault injection command is 0x%lx\n", cmd_n_channel);
	fsl_write(reconos_proc.proc_control_fsl_b, cmd_n_channel);
	fsl_write(reconos_proc.proc_control_fsl_b, sa0);
	fsl_write(reconos_proc.proc_control_fsl_b, sa1);
}

#define CMD_ARB_RUNTIME_OPTS 0xF1000000
extern void reconos_set_arb_runtime_opts(uint16_t arb_options){
	fsl_write(reconos_proc.proc_control_fsl_b, CMD_ARB_RUNTIME_OPTS);
	fsl_write(reconos_proc.proc_control_fsl_b, arb_options);

}

/*
 * Unused function?
 */
void reconos_proc_control_selftest(void)
{
	uint32_t res, expect = 0x5E1F7E57;

	fsl_write(reconos_proc.proc_control_fsl_b, 0x06000000);

	res = fsl_read(reconos_proc.proc_control_fsl_b);
	if (res != expect)
		whine("proc_control selftest part 1 failed "
		      "(read 0x%08X instead of 0x%08X)\n",
		      res, expect);
}

void reconos_cache_flush(void)
{
	int one = 1;
	write(reconos_proc.fd_cache, &one, sizeof(one));
}

void reconos_signal_handler(int sig, siginfo_t *siginfo, void * context) {
	ucontext_t* uc = (ucontext_t*) context;
	void * code_address;
	int32_t i;
	fprintf(stderr, "RECONOS_SIGNAL_HANDLER: started, stack around %p\n", &i);
#ifndef HOST_COMPILE
	code_address = (void*)uc->uc_mcontext.regs.pc,
#else
	code_address = (void*) uc->uc_mcontext.gregs[14],
#endif

	// Yeah, i know using printf in a signal context is not save.
	// But with a SIGSEGV the programm is messed up anyway, so what?
	fprintf(stderr,
			"%s: proc_control_thread ID %8lu killed at program address %p, tried to access %p.\n",
			(sig == SIGSEGV ? "SIGSEGV":(
			sig == SIGFPE  ? "SIGFPE": (
			sig == SIGILL  ? "SIGILL": "Unknown Signal"))),
			pthread_self(),
			code_address,
			(void*) siginfo->si_addr);
	if (sig == SIGILL){
		for (i=-64; i<=64; i+=4){
			fprintf(stderr, "SIGILL: Data at address %p: 0x%x\n",code_address+i, (*(uint32_t*)(code_address+i)) );
		}
		switch(siginfo->si_code){
		case ILL_ILLOPC: fprintf(stderr, "SIGILL Reason: illegal opcode\n"); break;
		case ILL_ILLOPN: fprintf(stderr, "SIGILL Reason: illegal operand\n"); break;
		case ILL_ILLADR: fprintf(stderr, "SIGILL Reason: illegal addressing mode\n"); break;
		case ILL_ILLTRP: fprintf(stderr, "SIGILL Reason: illegal trap\n"); break;
		case ILL_PRVOPC: fprintf(stderr, "SIGILL Reason: privileged opcode\n"); break;
		case ILL_PRVREG: fprintf(stderr, "SIGILL Reason: privileged register\n"); break;
		case ILL_COPROC: fprintf(stderr, "SIGILL Reason: coprocessor error\n"); break;
		case ILL_BADSTK: fprintf(stderr, "SIGILL Reason: internal stack error\n"); break;
		}
	}
#ifdef SHADOWING
	// Print OS call lists for debugging
	shadow_dump_all();
#endif

	sh_signal_error_handler("proc_control", sig, code_address, (void*) siginfo->si_addr);
}

#define C_RETURN_ADDR      0x00000001
#define C_RETURN_SELFTEST  0x00000002
#define C_RETURN_ERROR     0x00000003
static void *reconos_control_thread_entry(void *arg)
{
	// Install signal handler for segfaults, so wrong memory accesses of hardware threads can be handled
	struct sigaction act;
	act.sa_sigaction = reconos_signal_handler;
	sigemptyset (&act.sa_mask);
	act.sa_flags = SA_SIGINFO;
	sigaction(SIGSEGV, &act, NULL);
	sigaction(SIGFPE, &act, NULL);
	sigaction(SIGILL, &act, NULL);
	fprintf(stderr, "PROC_CONTROL_THREAD ID %8lu: started, stack around %p\n", pthread_self(), &act);
	while (1) {
		uint32_t cmd, ret, *addr;

		/* Receive page fault address */
		cmd = fsl_read(reconos_proc.proc_control_fsl_a);
		fprintf(stderr, "PROC_CONTROL_THREAD: cmd 0x%x\n", cmd);
		switch (cmd){
		case C_RETURN_ADDR:
			addr = (uint32_t *) fsl_read(reconos_proc.proc_control_fsl_a);
			reconos_proc.page_faults++;

			/* This page has not been touched yet.
			 * We can safely write 0 to the page */
			*addr = 0;
			reconos_cache_flush();
			ret = *addr;
	
			ret = ret & 0x00FFFFFF; /* Clear upper 8 bits */
			ret = ret | 0x03000000; /* Set page ready command */

			/* Note: the lower 24 bits of ret are ignored by the HW. */
			fsl_write(reconos_proc.proc_control_fsl_a, ret);
			break;

		case C_RETURN_SELFTEST:
			whine("proc_control selftest part 2 success\n");
			break;

		case C_RETURN_ERROR:
		{
			// What do we actually do here?
			// Maybe call the shadowing error handler?
			uint32_t err_type =  fsl_read(reconos_proc.proc_control_fsl_a);
			uint32_t err_addr =  fsl_read(reconos_proc.proc_control_fsl_a);
			sh_mem_error_handler(0xFF, err_type, err_addr);
		}
			break;
		default:
			sh_proc_control_error_handler(cmd);
			break;
		}
	}
	return NULL;
}

static int reconos_get_numfsl(void)
{
	unsigned int pvr3;

#ifndef HOST_COMPILE
	asm volatile ("mfs %0,rPVR3" : "=d" (pvr3));

#else
	pvr3 = 16;
#endif
	return 0x0000001F & (pvr3 >> 7);
}

int reconos_init(int proc_control_fsl_a, int proc_control_fsl_b)
{
	int i;
	uint32_t pgd;
	pthread_attr_t attr;

	reconos_proc.proc_control_fsl_a = proc_control_fsl_a;
	reconos_proc.proc_control_fsl_b = proc_control_fsl_b;
	reconos_proc.page_faults = 0;

	for (i = 0; i < SLOTS_MAX; i++)
		reconos_proc.slot_flags[i] |= SLOT_FLAG_RESET;
	fsl_write(proc_control_fsl_b, 0x04000000);

	pgd = reconos_getpgd();
	fsl_write(proc_control_fsl_b, 0x02000000);
	fsl_write(proc_control_fsl_b, pgd);

	pthread_attr_init(&attr);	
	pthread_create(&reconos_proc.proc_control_thread, NULL,
		       reconos_control_thread_entry, NULL);

	reconos_proc.fd_cache = open_or_die("/dev/getpgd", O_WRONLY);

	/*
	 * Setup default runtime options for memory arbiter
	 */
	reconos_set_arb_runtime_opts(ARB_ERROR_DETECTION_OFF | ARB_SHADOW_BUFFER_128K);

	return 0;
}

int reconos_init_autodetect(void)
{
	int num = reconos_get_numfsl();
	return reconos_init(num - 2, num - 1);
}

static void *reconos_delegate_thread_entry(void *arg);

int reconos_hwt_create(struct reconos_hwt *hwt, int slot, void *arg)
{
	hwt->slot = slot;
	return pthread_create(&hwt->delegate, NULL,
			      reconos_delegate_thread_entry, hwt);
}

void reconos_hwt_setresources(struct reconos_hwt *hwt,
			      struct reconos_resource *res,
			      size_t num_resources)
{
	hwt->resources = res;
	hwt->num_resources = num_resources;
}

extern void reconos_hwt_setprogram(struct reconos_hwt *hwt, const char * program_path){
	hwt->program_path = (char *) program_path;
}

void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data)
{
	hwt->init_data = init_data;
}

static inline void reconos_assert_type_and_res(struct reconos_hwt *hwt,
					       uint32_t handle, uint32_t type)
{
	if(handle >= hwt->num_resources){
		/*
		panic("wtf ... slot %d: resource id %d out of range, "
		      "must be lesser than %d\n", hwt->slot, handle,
		      hwt->num_resources);
		*/
		sh_osif_param_error_handler(hwt->slot, handle, hwt->num_resources, RECONOS_TYPE_INVALID, RECONOS_TYPE_INVALID);
	}

	if (hwt->resources[handle].type != type){
		/*
		panic("wtf ... slot %d: resource type 0x%08X expected, "
		      "found 0x%08X\n", hwt->slot, type,
		      hwt->resources[handle].type);
		*/
		sh_osif_param_error_handler(hwt->slot, handle, hwt->num_resources, hwt->resources[handle].type, type);
	}


}

static void reconos_delegate_process_mbox_get(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MBOX);

	fsl_write(hwt->slot, mbox_get(hwt->resources[handle].ptr));
}

static void reconos_delegate_process_mbox_put(struct reconos_hwt *hwt)
{
	//uint32_t handle = fsl_read(hwt->slot);
	//uint32_t arg0 = fsl_read(hwt->slot);

	struct {
		uint32_t handle;
		uint32_t arg0;
	} params;

	fsl_read_block(hwt->slot, &params, 2*sizeof(uint32_t));

	reconos_assert_type_and_res(hwt, params.handle, RECONOS_TYPE_MBOX);

	mbox_put(hwt->resources[params.handle].ptr, params.arg0);
	fsl_write(hwt->slot, 0);
}

static void reconos_delegate_process_sem_wait(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_SEM);

	fsl_write(hwt->slot, sem_wait(hwt->resources[handle].ptr));
}

static void reconos_delegate_process_sem_post(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_SEM);

	sem_post(hwt->resources[handle].ptr);
	fsl_write(hwt->slot, 0);
}

static void reconos_delegate_process_mutex_lock(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	fsl_write(hwt->slot, pthread_mutex_lock(hwt->resources[handle].ptr));
}

static void reconos_delegate_process_mutex_unlock(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	pthread_mutex_unlock(hwt->resources[handle].ptr);
	fsl_write(hwt->slot, 0);
}

static void reconos_delegate_process_mutex_trylock(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	fsl_write(hwt->slot, pthread_mutex_trylock(hwt->resources[handle].ptr));
}

static void reconos_delegate_process_cond_wait(struct reconos_hwt *hwt)
{
	//uint32_t handle = fsl_read(hwt->slot);
	//uint32_t handle2 = fsl_read(hwt->slot);

	struct {
		uint32_t handle;
		uint32_t handle2;
	} params;
	fsl_read_block(hwt->slot, &params, 2*sizeof(uint32_t));

	reconos_assert_type_and_res(hwt, params.handle, RECONOS_TYPE_COND);
	reconos_assert_type_and_res(hwt, params.handle2, RECONOS_TYPE_MUTEX);

	fsl_write(hwt->slot, pthread_cond_wait(hwt->resources[params.handle].ptr,
					       hwt->resources[params.handle2].ptr));
}

static void reconos_delegate_process_cond_signal(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_COND);

	pthread_cond_signal(hwt->resources[handle].ptr);
	fsl_write(hwt->slot, 0);
}

static void reconos_delegate_process_cond_broadcast(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_COND);

	pthread_cond_broadcast(hwt->resources[handle].ptr);
	fsl_write(hwt->slot, 0);
}

static void reconos_delegate_process_rqueue_receive(struct reconos_hwt *hwt)
{
	//int i;
	ssize_t res;
	//uint32_t handle, arg0;
	uint32_t msg_size, *msg;

	struct {
		uint32_t handle;
		uint32_t arg0;
	} params;

	fsl_read_block(hwt->slot, &params, 2*sizeof(uint32_t));

	//handle = fsl_read(hwt->slot);
	//arg0 = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, params.handle, RECONOS_TYPE_RQ);

	msg_size = params.arg0;
	msg = xmalloc_aligned(msg_size+sizeof(uint32_t), sizeof(void *) * 8);
	msg[0] = msg_size;

	res = rq_receive(hwt->resources[params.handle].ptr, msg+1, msg_size);
	if (res <= 0 || res > msg_size) {
		fsl_write(hwt->slot, 0);
		free(msg);
		sh_generic_error_handler("Error in rq_receive()\n");
	}

	fsl_write_block(hwt->slot, msg, msg_size+sizeof(uint32_t));
	//fsl_write(hwt->slot, (uint32_t) res);
	///* FIXME: write data to hw thread */
	//for (i = 0; i < res / sizeof(uint32_t); ++i)
	//	fsl_write(hwt->slot, msg[i]);

	free(msg);
}

static void reconos_delegate_process_rqueue_send(struct reconos_hwt *hwt)
{
	//int i;
	//uint32_t handle, arg0;
	uint32_t msg_size, *msg;

	struct {
		uint32_t handle;
		uint32_t arg0;
	} params;

	fsl_read_block(hwt->slot, &params, 2*sizeof(uint32_t));

	//handle = fsl_read(hwt->slot);
	//arg0 = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, params.handle, RECONOS_TYPE_RQ);

	msg_size = params.arg0;
	msg = xmalloc_aligned(msg_size, sizeof(void *) * 8); 

	///* FIXME: read data to hw thread */
	//for (i = 0; i < msg_size / sizeof(uint32_t); ++i)
	//	msg[i] = fsl_read(hwt->slot);

	fsl_read_block(hwt->slot, msg, msg_size);

	rq_send(hwt->resources[params.handle].ptr, msg, msg_size);
	fsl_write(hwt->slot, 0);
	free(msg);
}

static void reconos_delegate_process_thread_yield(struct reconos_hwt *hwt)
{
	pthread_yield(); // actually a shadow_yield(), substituted by thread_shadowing_subs.h
	fsl_write(hwt->slot, 1);
}

static void reconos_delegate_process_load_program(struct reconos_hwt *hwt){
#define PROGRAM_FILE_OFFSET 0x800
	int error;
	struct stat stats;
	off_t program_size;
	FILE * program_file;
	size_t elements_read;
	error = stat(hwt->program_path, &stats);
	uint32_t * program_buffer = NULL;

	if (error){
		free(program_buffer);
		sh_generic_error_handler("couldn't find program file %s\n", hwt->program_path);
	}
	program_size = stats.st_size;

	program_file = fopen(hwt->program_path, "r");
	if (!program_file){
		free(program_buffer);
		sh_generic_error_handler("couldn't find program file %s\n", hwt->program_path);
	}

	program_buffer = malloc(program_size-PROGRAM_FILE_OFFSET);
	if(!program_buffer){
		free(program_buffer);
		sh_generic_error_handler("couldn't allocate buffer for program file %s of size %i\n", hwt->program_path, program_size);
	}

	error = fseek(program_file, PROGRAM_FILE_OFFSET , SEEK_SET);
	if (error){
		free(program_buffer);
		sh_generic_error_handler("couldn't seek in program file %s to %i \n", hwt->program_path, error);
	}

	elements_read = fread(program_buffer, program_size - PROGRAM_FILE_OFFSET, 1, program_file);
	if (elements_read != 1){
		free(program_buffer);
		sh_generic_error_handler("couldn't read program file %s. Tried to read %i bytes. fread() read %i elements.\n", hwt->program_path,program_size - PROGRAM_FILE_OFFSET, elements_read);
	}

	fsl_write(hwt->slot, program_size-PROGRAM_FILE_OFFSET);
	fsl_write_block(hwt->slot, program_buffer, program_size-PROGRAM_FILE_OFFSET);
	printf("Loaded program %s\n", hwt->program_path);

	free(program_buffer);
}

static void reconos_delegate_process_get_init_data(struct reconos_hwt *hwt)
{
	fsl_write(hwt->slot, (uint32_t) hwt->init_data);
}

static void *reconos_delegate_thread_entry(void *arg)
{
	struct reconos_hwt *hwt = arg;
	fprintf(stderr, "DELEGATE_THREAD ID %8lu: started, stack around %p\n", pthread_self(), &hwt);
	reconos_slot_reset(hwt->slot, 1);
	reconos_slot_reset(hwt->slot, 0);

	while (1) {
		uint32_t cmd = fsl_read(hwt->slot);
		switch (cmd) {
		case RECONOS_CMD_MBOX_GET:
			reconos_delegate_process_mbox_get(hwt);
			break;	
		case RECONOS_CMD_MBOX_PUT:
			reconos_delegate_process_mbox_put(hwt);
			break;
		case RECONOS_CMD_SEM_WAIT:
			reconos_delegate_process_sem_wait(hwt);
			break;	
		case RECONOS_CMD_SEM_POST:
			reconos_delegate_process_sem_post(hwt);
			break;
		case RECONOS_CMD_MUTEX_LOCK:
			reconos_delegate_process_mutex_lock(hwt);
			break;	
		case RECONOS_CMD_MUTEX_UNLOCK:
			reconos_delegate_process_mutex_unlock(hwt);
			break;
		case RECONOS_CMD_MUTEX_TRYLOCK:
			reconos_delegate_process_mutex_trylock(hwt);
			break;
		case RECONOS_CMD_COND_WAIT:
			reconos_delegate_process_cond_wait(hwt);
			break;
		case RECONOS_CMD_COND_SIGNAL:
			reconos_delegate_process_cond_signal(hwt);
			break;
		case RECONOS_CMD_COND_BROADCAST:
			reconos_delegate_process_cond_broadcast(hwt);
			break;
		case RECONOS_CMD_RQ_RECEIVE:
			reconos_delegate_process_rqueue_receive(hwt);
			break;
		case RECONOS_CMD_RQ_SEND:
			reconos_delegate_process_rqueue_send(hwt);
			break;
	    case RECONOS_CMD_THREAD_YIELD:
	    	reconos_delegate_process_thread_yield(hwt);
			break;
		case RECONOS_CMD_THREAD_GET_INIT_DATA:
			reconos_delegate_process_get_init_data(hwt);
			break;
		case RECONOS_CMD_THREAD_LOAD_PROGRAM:
			reconos_delegate_process_load_program(hwt);
			break;
		case RECONOS_CMD_THREAD_EXIT:
			return NULL;
		default:
			sh_osif_function_error_handler(hwt->slot, cmd);
			break;
		}
	}

	return NULL;
}
