#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "reconos.h"
#include "fsl.h"
#include "mbox.h"
#include "rqueue.h"
#include "xutils.h"

#define RECONOS_DEBUG(x, ...)
#define RECONOS_ERROR(x, ...)

static struct reconos_process reconos_proc;

static void reconos_slot_reset(int num, int reset)
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
	if (res != sizeof(pgd))
		panic("Read error from /dev/getpgd!\n");

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

void reconos_proc_control_selftest(void)
{
	uint32_t res, expect = 0x5E1F7E57;

	fsl_write(reconos_proc.proc_control_fsl_b, 0x06000000);

	res = fsl_read(reconos_proc.proc_control_fsl_b);
	if (res == expect)
		whine("proc_control selftest part 1 success\n");
	else
		whine("proc_control selftest part 1 failed "
		      "(read 0x%08X instead of 0x%08X)\n",
		      res, expect);
}

void reconos_cache_flush(void)
{
	int one = 1;
	write(reconos_proc.fd_cache, &one, sizeof(one));
}

static void *reconos_control_thread_entry(void *arg)
{
	while (1) {
		uint32_t cmd, ret, *addr;

		/* Receive page fault address */
		cmd = fsl_read(reconos_proc.proc_control_fsl_a);
		if (cmd == 0x00000001) {	
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
		}
		if (cmd == 0x00000002)
			whine("proc_control selftest part 2 success\n");
	}
}

static int reconos_get_numfsl(void)
{
	unsigned int pvr3;

	asm volatile ("mfs %0,rPVR3" : "=d" (pvr3));

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

	return 0;
}

int reconos_init_autodetect(void)
{
	int num = reconos_get_numfsl();
	return reconos_init(num - 2, num - 1);
}

static void *reconos_delegate_thread_entry(void *arg);

int reconos_hwt_create(struct reconos_hwt * hwt, int slot, void *arg)
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

void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data)
{
	hwt->init_data = init_data;
}

static void reconos_delegate_process_mbox_get(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_mbox_put(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_sem_wait(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_sem_post(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_mutex_lock(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_mutex_unlock(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_mutex_trylock(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_cond_wait(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_cond_signal(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_cond_broadcast(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_rqueue_receive(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_rqueue_send(struct reconos_hwt *hwt)
{
}

static void reconos_delegate_process_get_init_data(struct reconos_hwt *hwt)
{
}

static void *reconos_delegate_thread_entry(void *arg)
{
	struct reconos_hwt *hwt = arg;

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
		case RECONOS_CMD_THREAD_GET_INIT_DATA:
			reconos_delegate_process_get_init_data(hwt);
			break;
		case RECONOS_CMD_THREAD_EXIT:
			return NULL;
		default:
			die();
		}
	}

	return NULL;
}
