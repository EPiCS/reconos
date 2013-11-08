/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/percpu.h>
#include <linux/cache.h>
#include <linux/proc_fs.h>
#include <linux/rcupdate.h>
#include <linux/hrtimer.h>
#include <linux/interrupt.h>

#include "xt_engine.h"
#include "xt_fblock.h"

struct engine_iostats {
	unsigned long long bytes;
	unsigned long long pkts;
	unsigned long long fblocks;
	unsigned long long timer;
	unsigned long long timer_cpu_miss;
} ____cacheline_aligned;

struct engine_disc {
	struct sk_buff_head ppe_backlog_queue;
	struct tasklet_hrtimer htimer;
	int active, cpu;
} ____cacheline_aligned;

static struct engine_iostats __percpu *iostats;
static struct engine_disc __percpu *emdiscs;
extern struct proc_dir_entry *lana_proc_dir;
static struct proc_dir_entry *engine_proc;

static inline void engine_inc_pkts_stats(void)
{
	this_cpu_inc(iostats->pkts);
}

static inline void engine_inc_fblock_stats(void)
{
	this_cpu_inc(iostats->fblocks);
}

static inline void engine_inc_timer_stats(void)
{
	this_cpu_inc(iostats->timer);
}

static inline void engine_inc_timer_cpu_miss_stats(void)
{
	this_cpu_inc(iostats->timer_cpu_miss);
}

static inline void engine_add_bytes_stats(unsigned long bytes)
{
	this_cpu_add(iostats->bytes, bytes);
}

void engine_backlog_tail(struct sk_buff *skb, enum path_type dir)
{
	write_path_to_skb(skb, dir);
	skb_queue_tail(&(this_cpu_ptr(emdiscs)->ppe_backlog_queue), skb);
	
}
EXPORT_SYMBOL(engine_backlog_tail);

static inline struct sk_buff *engine_backlog_test_reduce(enum path_type *dir)
{
	struct sk_buff *skb = NULL;
	if ((skb = skb_dequeue(&(this_cpu_ptr(emdiscs)->ppe_backlog_queue))))
		(*dir) = read_path_from_skb(skb);
	return skb;
}

static inline struct sk_buff *
engine_backlog_queue_test_reduce(enum path_type *dir, struct sk_buff_head *list)
{
	struct sk_buff *skb = NULL;
	if ((skb = skb_dequeue(list)))
		(*dir) = read_path_from_skb(skb);
	return skb;
}

static inline void engine_this_cpu_set_active(void)
{
	this_cpu_write(emdiscs->active, 1);
}

static inline void engine_this_cpu_set_inactive(void)
{
	this_cpu_write(emdiscs->active, 0);
}

static inline int engine_this_cpu_is_active(void)
{
	return this_cpu_read(emdiscs->active);
}

int process_packet(struct sk_buff *skb, enum path_type dir)
{
	int ret;
	idp_t cont;
	struct fblock *fb;
	//printk(KERN_INFO "[engine] process packet called\n");	

	BUG_ON(!rcu_read_lock_held());

	if (engine_this_cpu_is_active()) {
		engine_backlog_tail(skb, dir);
		return 0;
	}
pkt:
	ret = PPE_ERROR;

	engine_this_cpu_set_active();
	engine_inc_pkts_stats();
	engine_add_bytes_stats(skb->len);
	
	while ((cont = read_next_idp_from_skb(skb))) {
		struct fblock_stats *stats;
		u64 before, after;
	//	printk(KERN_INFO "[engine] read IDP %d\n", cont);	

		fb = __search_fblock(cont);
	//	printk(KERN_INFO "[engine] next block %s\n", fb->name);	

		if (unlikely(!fb)) {
			kfree_skb(skb);
			ret = PPE_ERROR;
			break;
		}

		if (fblock_transition_inbound_isset(fb)) {
			engine_backlog_tail(skb, dir);
			put_fblock(fb);
			goto out;
		}

		if (fblock_offload_isset(fb)) {
			packet_sw_to_hw(skb, dir);
			put_fblock(fb);
			goto out_next;
		}
	//	printk(KERN_INFO "[engine] read IDP a %d\n", cont);	
		
		stats = this_cpu_ptr(fb->stats);
	//	printk(KERN_INFO "[engine] read IDP b %d\n", cont);	

		before = get_jiffies_64();
		ret = fb->netfb_rx(fb, skb, &dir);
		after = get_jiffies_64();
	//	printk(KERN_INFO "[engine] read IDP c %d\n", cont);	
#ifdef blub //TODO: there is somethinng wrong with the stats.
		u64_stats_update_begin(&stats->syncp);
		stats->packets++;
		stats->bytes += skb->len;
		u64_stats_update_end(&stats->syncp);
		stats->time = after - before;;
	//	printk(KERN_INFO "[engine] read IDP d %d\n", cont);	
#endif 
		engine_inc_fblock_stats();

		if (ret == PPE_DROPPED) {
			stats->dropped++;
			put_fblock(fb);
			break;
		}

		put_fblock(fb);
		
		if (ret == PPE_HALT_NO_REDUCE)
			goto out;
	//	printk(KERN_INFO "[engine] read IDP e %d\n", cont);	

	}

out_next:
	if ((skb = engine_backlog_test_reduce(&dir)))
		goto pkt;
out:
	engine_this_cpu_set_inactive();

	return ret;
}
EXPORT_SYMBOL_GPL(process_packet);

static enum hrtimer_restart engine_timer_handler(struct hrtimer *self)
{
	enum path_type dir = TYPE_EGRESS;
	struct sk_buff *skb;
	struct tasklet_hrtimer *thr = container_of(self, struct tasklet_hrtimer, timer);
	struct engine_disc *disc = container_of(thr, struct engine_disc, htimer);
//	printk(KERN_INFO "[engine] engine_timer_handler\n");	
	
	if (likely(ACCESS_ONCE(disc->active)))
		goto out;
	if (skb_queue_empty(&disc->ppe_backlog_queue))
		goto out;
	if (disc->cpu != smp_processor_id())
		engine_inc_timer_cpu_miss_stats();

	rcu_read_lock();

	skb = engine_backlog_queue_test_reduce(&dir, &disc->ppe_backlog_queue);
	if (unlikely(!skb)) {
		rcu_read_unlock();
		goto out;
	}
	process_packet(skb, dir);
//	printk(KERN_INFO "[engine] 1\n");

	rcu_read_unlock();
//	printk(KERN_INFO "[engine] 2\n");

out:
	engine_inc_timer_stats();
//	printk(KERN_INFO "[engine] 3\n");

	if (!skb_queue_empty(&disc->ppe_backlog_queue))
		tasklet_hrtimer_start(thr, ktime_set(0, 1), HRTIMER_MODE_REL);
	else
		tasklet_hrtimer_start(thr, ktime_set(0, 100000000), HRTIMER_MODE_REL);
//	printk(KERN_INFO "[engine] 4\n");

	return HRTIMER_NORESTART;
}

static int engine_procfs(char *page, char **start, off_t offset,
			 int count, int *eof, void *data)
{
	unsigned int cpu;
	off_t len = 0;

	len += sprintf(page + len,
		       "cpu|pkts|bytes|fblocks|timer-call"
		       "|timer-cpu-miss|backlog-queue\n");
	get_online_cpus();

	for_each_online_cpu(cpu) {
		struct engine_iostats *iostats_cpu;
		struct engine_disc *emdisc_cpu;
		iostats_cpu = per_cpu_ptr(iostats, cpu);
		emdisc_cpu = per_cpu_ptr(emdiscs, cpu);
		len += sprintf(page + len, "CPU%u:\t%llu\t%llu\t%llu\t%llu\t%llu\t%u\n",
			       cpu, iostats_cpu->pkts, iostats_cpu->bytes,
			       iostats_cpu->fblocks, iostats_cpu->timer,
			       iostats_cpu->timer_cpu_miss,
			       skb_queue_len(&emdisc_cpu->ppe_backlog_queue));
	}

	put_online_cpus();
        /* FIXME: fits in page? */

        *eof = 1;
        return len;
}

int init_engine(void)
{
	unsigned int cpu;

	iostats = alloc_percpu(struct engine_iostats);
	if (!iostats)
		return -ENOMEM;

	get_online_cpus();

	for_each_online_cpu(cpu) {
		struct engine_iostats *iostats_cpu;

		iostats_cpu = per_cpu_ptr(iostats, cpu);
		iostats_cpu->bytes = 0;
		iostats_cpu->pkts = 0;
		iostats_cpu->fblocks = 0;
		iostats_cpu->timer = 0;
		iostats_cpu->timer_cpu_miss = 0;
	}

	put_online_cpus();

	emdiscs = alloc_percpu(struct engine_disc);
	if (!emdiscs)
		goto err;

	get_online_cpus();

	for_each_online_cpu(cpu) {
		struct engine_disc *emdisc_cpu;

		emdisc_cpu = per_cpu_ptr(emdiscs, cpu);
		emdisc_cpu->active = 0;
		emdisc_cpu->cpu = cpu;

		skb_queue_head_init(&emdisc_cpu->ppe_backlog_queue);
		tasklet_hrtimer_init(&emdisc_cpu->htimer,
				     engine_timer_handler,
				     CLOCK_REALTIME, HRTIMER_MODE_ABS);
		tasklet_hrtimer_start(&emdisc_cpu->htimer,
				      ktime_set(0, 100000000),
				      HRTIMER_MODE_REL);
	}

	put_online_cpus();

	engine_proc = create_proc_read_entry("ppe", 0400, lana_proc_dir,
					     engine_procfs, NULL);
	if (!engine_proc)
		goto err1;
	return 0;
err1:
	free_percpu(emdiscs);
err:
	free_percpu(iostats);
	return -ENOMEM;
}
EXPORT_SYMBOL_GPL(init_engine);

void cleanup_engine(void)
{
	unsigned int cpu;
	if (iostats)
		free_percpu(iostats);
	if (emdiscs) {
		get_online_cpus();

		for_each_online_cpu(cpu) {
			struct engine_disc *emdisc_cpu;

			emdisc_cpu = per_cpu_ptr(emdiscs, cpu);
			tasklet_hrtimer_cancel(&emdisc_cpu->htimer);
			skb_queue_purge(&emdisc_cpu->ppe_backlog_queue);
		}

		put_online_cpus();

		free_percpu(emdiscs);
	}

	remove_proc_entry("ppe", lana_proc_dir);
}
EXPORT_SYMBOL_GPL(cleanup_engine);
