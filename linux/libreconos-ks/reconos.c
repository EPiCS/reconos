/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2012 Andreas Agne <agne@upb.de>
 */

#include <linux/module.h>
#include <linux/sched.h>
#include <linux/kthread.h>
#include <linux/kernel.h>

#include "reconos.h"
#include "mbox.h"

extern uint32_t fsl_read_word(int num);
extern ssize_t fsl_write_word(int num, uint32_t val);

extern void getpgd_flush_dcache(void);
extern unsigned long getpgd_fetch_pgd(void);

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
	fsl_write_word(reconos_proc.proc_control_fsl_b, cmd);
}

static inline uint32_t reconos_getpgd(void)
{
	return (uint32_t) getpgd_fetch_pgd();
}

void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
		       uint32_t *page_faults)
{
	uint32_t hits, misses;

	/* XXX: @aagne: can we make defines for 0x05000000 and co? ---DB */
	fsl_write_word(reconos_proc.proc_control_fsl_b, 0x05000000);

	hits = fsl_read_word(reconos_proc.proc_control_fsl_b);
	misses = fsl_read_word(reconos_proc.proc_control_fsl_b);

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

	fsl_write_word(reconos_proc.proc_control_fsl_b, 0x06000000);

	res = fsl_read_word(reconos_proc.proc_control_fsl_b);
	if (res != expect)
		printk(KERN_WARNING "proc_control selftest part 1 failed "
		       "(read 0x%08X instead of 0x%08X)\n",
		       res, expect);
	else
		printk(KERN_INFO "proc_control selftest part 1 passed\n");
}

void reconos_cache_flush(void)
{
	getpgd_flush_dcache();
}

static int reconos_control_thread_entry(void *arg)
{
	printk("[reconos] control thread running\n");

	while (likely(!kthread_should_stop())) {
		uint32_t cmd, ret, *addr;

		/* Receive page fault address */
		cmd = fsl_read_word(reconos_proc.proc_control_fsl_a);
		if (cmd == 0x00000001) {	
			addr = (uint32_t *)
				fsl_read_word(reconos_proc.proc_control_fsl_a);
			reconos_proc.page_faults++;

			/* This page has not been touched yet.
			 * We can safely write 0 to the page */
			*addr = 0;
			reconos_cache_flush();
			ret = *addr;

			ret = ret & 0x00FFFFFF; /* Clear upper 8 bits */
			ret = ret | 0x03000000; /* Set page ready command */

			/* Note: the lower 24 bits of ret are ignored by the HW. */
			fsl_write_word(reconos_proc.proc_control_fsl_a, ret);
		}
		if (cmd == 0x00000002)
			printk(KERN_INFO "proc_control selftest part 2 success\n");
	}

	printk("[reconos] control thread halted\n");
	return 0;
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

	reconos_proc.proc_control_fsl_a = proc_control_fsl_a;
	reconos_proc.proc_control_fsl_b = proc_control_fsl_b;
	reconos_proc.page_faults = 0;

	for (i = 0; i < SLOTS_MAX; i++)
		reconos_proc.slot_flags[i] |= SLOT_FLAG_RESET;
	fsl_write_word(proc_control_fsl_b, 0x04000000);

	pgd = reconos_getpgd();
	fsl_write_word(proc_control_fsl_b, 0x02000000);
	fsl_write_word(proc_control_fsl_b, pgd);

	reconos_proc.proc_control_thread =
		kthread_create(reconos_control_thread_entry, NULL,
			       "reconos-ctl");
	if (IS_ERR(reconos_proc.proc_control_thread)) {
		printk(KERN_ERR "[reconos] Error creating thread!\n");
		return -EIO;
	}

	wake_up_process(reconos_proc.proc_control_thread);
	return 0;
}

int reconos_init_autodetect(void)
{
	int num = reconos_get_numfsl();
	return reconos_init(num - 2, num - 1);
}

static int reconos_delegate_thread_entry(void *arg);

int reconos_hwt_create(struct reconos_hwt *hwt, int slot, void *arg)
{
	hwt->slot = slot;
	hwt->delegate = kthread_create(reconos_delegate_thread_entry, hwt,
				       "reconos-hwt%d", hwt->slot);
        if (IS_ERR(hwt->delegate)) {
                printk(KERN_ERR "[reconos] Error creating thread!\n");
                return -EIO;
        }

        wake_up_process(hwt->delegate);
	return 0;
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

static inline void reconos_assert_type_and_res(struct reconos_hwt *hwt,
					       uint32_t handle, uint32_t type)
{
	if (handle >= hwt->num_resources) {
		printk(KERN_ERR "wtf ... slot %d: resource id %d out of "
		       "range, must be lesser than %d\n", hwt->slot, handle,
		       hwt->num_resources);
		BUG();
	}

	if (hwt->resources[handle].type != type) {
		printk(KERN_ERR "wtf ... slot %d: resource type 0x%08X "
		      "expected, found 0x%08X\n", hwt->slot, type,
		      hwt->resources[handle].type);
		BUG();
	}
}

static void reconos_delegate_process_mbox_get(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MBOX);

	fsl_write_word(hwt->slot, mbox_get(hwt->resources[handle].ptr));
}

static void reconos_delegate_process_mbox_put(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);
	uint32_t arg0 = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MBOX);

	mbox_put(hwt->resources[handle].ptr, arg0);
	fsl_write_word(hwt->slot, 0);
}

static void reconos_delegate_process_sem_wait(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_SEM);

	down(hwt->resources[handle].ptr);
	fsl_write_word(hwt->slot, 0);
}

static void reconos_delegate_process_sem_post(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_SEM);

	up(hwt->resources[handle].ptr);
	fsl_write_word(hwt->slot, 0);
}

static void reconos_delegate_process_mutex_lock(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	mutex_lock(hwt->resources[handle].ptr);
	fsl_write_word(hwt->slot, 0);
}

static void reconos_delegate_process_mutex_unlock(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	mutex_unlock(hwt->resources[handle].ptr);
	fsl_write_word(hwt->slot, 0);
}

static void reconos_delegate_process_mutex_trylock(struct reconos_hwt *hwt)
{
	int ret;
	uint32_t handle = fsl_read_word(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MUTEX);

	ret = mutex_trylock(hwt->resources[handle].ptr);
	/* Returns 1 if the mutex has been acquired successfully, and 0 on 
	 * contention. We need to apdapt that to pthread_mutex_trylock :-/ */
	if (ret == 0)
		ret = -EBUSY;
	else if (ret == 1)
		ret = 0;
	fsl_write_word(hwt->slot, (uint32_t) ret);
}

static void reconos_delegate_process_get_init_data(struct reconos_hwt *hwt)
{
	fsl_write_word(hwt->slot, (uint32_t) hwt->init_data);
}

static int reconos_delegate_thread_entry(void *arg)
{
	struct reconos_hwt *hwt = arg;

	reconos_slot_reset(hwt->slot, 1);
	reconos_slot_reset(hwt->slot, 0);

	while (likely(!kthread_should_stop())) {
		uint32_t cmd = fsl_read_word(hwt->slot);

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
		case RECONOS_CMD_THREAD_GET_INIT_DATA:
			reconos_delegate_process_get_init_data(hwt);
			break;
		case RECONOS_CMD_THREAD_EXIT:
			return 0;
		case RECONOS_CMD_COND_WAIT:
		case RECONOS_CMD_COND_SIGNAL:
		case RECONOS_CMD_COND_BROADCAST:
		case RECONOS_CMD_RQ_RECEIVE:
		case RECONOS_CMD_RQ_SEND:
		default:
			/* Unsupported, dummy read */
			BUG();
		}
	}

	return 0;
}

static int __init init_reconos_module(void)
{
	printk("[reconos] library loaded\n");
	return 0;
}

static void __exit cleanup_reconos_module(void)
{
	printk("[reconos] library unloaded\n");
}

module_init(init_reconos_module);
module_exit(cleanup_reconos_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("ReconOS lib module");
