/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <syslog.h>
#include <sys/time.h>

#include "plugin.h"
#include "locking.h"
#include "xutils.h"
#include "sched.h"

struct task {
	long delta;			/* in us */
	unsigned long interval;		/* in us */
	struct plugin_instance *plugin;	/* plugin */
	struct task *next;		/* next in list */
};

#define TIMER_SLEEP_INT	250000

static struct task *list_head = NULL;
static struct timeval t_last;
static struct mutexlock lock;

static void __sched_delta_queue_insert_task(struct task *t, int in_irq);

static inline void sched_set_timeout(struct timeval *timeval,
				     unsigned long usec)
{
	timeval->tv_sec = (long) (usec / (1000 * 1000));
	timeval->tv_usec = usec - (timeval->tv_sec * (1000 * 1000));
}

static inline unsigned long sched_get_timeout(struct timeval *timeval)
{
	return timeval->tv_sec * (1000 * 1000) + timeval->tv_usec;
}

static inline struct timeval sched_tv_subtract(struct timeval time1,
					       struct timeval time2)
{
	/* time1 - time2 */
	struct timeval result;

	if ((time1.tv_sec < time2.tv_sec) ||
	    ((time1.tv_sec == time2.tv_sec) &&
	    (time1.tv_usec <= time2.tv_usec))) {
		result.tv_sec = result.tv_usec = 0;
	} else {
		result.tv_sec = time1.tv_sec - time2.tv_sec;

		if (time1.tv_usec < time2.tv_usec) {
			result.tv_usec = time1.tv_usec + 1000000L -
					 time2.tv_usec;
			result.tv_sec--;
		} else {
			result.tv_usec = time1.tv_usec - time2.tv_usec ;
		}
	}

	return result;
}

static inline void sched_timer_set_interval(unsigned long interval)
{
	struct itimerval val;

	memset(&val, 0, sizeof(val));
	sched_set_timeout(&val.it_value, interval);
	sched_set_timeout(&val.it_interval, 0);

	setitimer(ITIMER_REAL, &val, NULL);
	gettimeofday(&t_last, NULL);
}

static inline unsigned long sched_timer_get_interval(void)
{
	struct timeval t_now, t_val;

	gettimeofday(&t_now, NULL);
	t_val = sched_tv_subtract(t_now, t_last);	

	return sched_get_timeout(&t_val);
}

static void __sched_timer_update_delta(long delta)
{
	struct task *t = list_head;

	while (t != NULL) {
		if (t->delta >= delta) {
			t->delta -= delta;
			break;
		} else {
			delta -= t->delta;
			t->delta = 0;
			t = t->next;  
		}
	}
}

static void sched_timer_interrupt(int signal)
{
	unsigned long curr_interval = sched_timer_get_interval();

	if (signal != SIGALRM)
		return;

	mutexlock_lock(&lock);

	if (list_head == NULL) {
		sched_timer_set_interval(TIMER_SLEEP_INT);
		goto out;
	}

	__sched_timer_update_delta(curr_interval);

	while (list_head != NULL) {
		struct task *t = list_head;

		if (t->delta < 1) {
			t->plugin->fetch(t->plugin);

			list_head = t->next;
			t->next = NULL;
			__sched_delta_queue_insert_task(t, 1);
		} else {
			sched_timer_set_interval(t->delta);
			break;
		}
	}

out:
	mutexlock_unlock(&lock);
}

static void __sched_delta_queue_insert_task(struct task *t, int in_irq)
{
	unsigned long cnt;
	struct task *prev, *curr;

	t->delta += t->interval;

	if (list_head == NULL) {
		t->next = NULL;
		list_head = t;

		if (!in_irq)
			sched_timer_set_interval(t->delta);
		return;
	}

	cnt = list_head->delta;
	if (cnt > t->delta) {
		list_head->delta = cnt - t->delta;

		t->next = list_head;
		list_head = t;

		if (!in_irq)
			sched_timer_set_interval(t->delta);
		return;
	}

	t->delta -= cnt;

	prev = list_head;
	curr = list_head->next;

	while (curr != NULL) {
		if (t->delta <= curr->delta) {
			curr->delta -= t->delta;
			t->next = curr;
			prev->next = t;
			return;
		}

		t->delta -= curr->delta;
		prev = curr;
		curr = curr->next;
	}

	prev->next = t;
	t->next = NULL;
}

static void sched_delta_queue_insert_task(struct task *t, int in_irq)
{
	mutexlock_lock(&lock);
	__sched_delta_queue_insert_task(t, in_irq);
	mutexlock_unlock(&lock);
}

static void sched_delta_queue_remove_task(struct task *t)
{
	/* stub */
}

void sched_register_task(struct plugin_instance *p)
{
	struct task *t = xmalloc(sizeof(*t));
	t->plugin = p;
	t->interval = p->schedule_int < 1 ? 1 : p->schedule_int;
	t->delta = 0;
	t->next = NULL;

	sched_delta_queue_insert_task(t, 0);
}

void sched_unregister_task(struct plugin_instance *p)
{
	/* stub */
}

static void sched_register_signal_f(int signal, void (*handler)(int), int flags)
{
	sigset_t block_mask;
	struct sigaction saction;

	sigfillset(&block_mask);

	saction.sa_handler = handler;
	saction.sa_mask = block_mask;
	saction.sa_flags = flags;
	sigaction(signal, &saction, NULL);
}

void sched_main(void)
{
	mutexlock_init(&lock);
	sched_register_signal_f(SIGALRM, sched_timer_interrupt, SA_SIGINFO);
	sched_timer_set_interval(TIMER_SLEEP_INT);

	while (1) {
		sleep(10);
	}

	sched_timer_set_interval(0);
	mutexlock_destroy(&lock);
}
