	/*
	 * Lightweight Autonomic Network Architecture
	 *
	 * crr_tx test module.
	 *
	 * Copyright 2011 Florian Deragisch <floriade@ee.ethz.ch>,
	 * Swiss federal institute of technology (ETH Zurich)
	 * Subject to the GPL.
	 */

	/* TODO:
	 *
	 * Don't use seq nr, which is still not ACK'ed ( 1 - 2 ACK 3 ACK 4 ACK 1 X )! DONE
	 * We need 2*WIN_SZ timers (1 - 2 ACK 3 ACK <- X) would stop timer 1! DONE
	 * Fix Timeout retransmission! DONE
	 * Change seq and ack structure for bigger window size. DONE
	 * Check if receiving is an open packet -> Affects spoofing. DONE
	 * Reset von Seq Nr für neue Transfers? -> Not important Seq Nr is being 
	 * tracked from kernel space not user space! DONE
	 */

	/* Important!
	 *
	 * Packets coming from userspace, that are using the PF_LANA socket, are raw
	 * packets. The data pointer points to the ETH_HDR, unlike packtes that have
	 * passed the kernel already. For those packets data points after ETH_TYPE
	 * 
	 */


	#include <linux/kernel.h>
	#include <linux/module.h>
	#include <linux/spinlock.h>
	#include <linux/notifier.h>
	#include <linux/rcupdate.h>
	#include <linux/seqlock.h>
	#include <linux/percpu.h>
	#include <linux/prefetch.h>
	#include <linux/if_ether.h>
	#include <linux/hrtimer.h>
	#include <linux/interrupt.h>

	#include "xt_fblock.h"
	#include "xt_engine.h"

	#define ETH_HDR_LEN	14
	#define WIN_SZ		2
	#define WIN_SZ_SMALL								//for WIN_SZ smaller than 4 otherwise comment it out
	#define ACK_LEN		1
	#define MAX_QUEUE_LEN	500
	#define MIN_QUEUE_LEN	100							
	//#define MAX_RTT		2*HZ

	//#define SET_BIT(x, y)	x | (1 << (y - 1))
	//#define UNSET_BIT(x,y) 	x & ~(1 << (y - 1))

	#define ISBITSET(x,i) ((x[i>>3] & (1<<(i&7)))!=0)
	#define SETBIT(x,i) x[i>>3]|=(1<<(i&7));
	#define CLEARBIT(x,i) x[i>>3]&=(1<<(i&7))^0xFF;

	#ifdef WIN_SZ_SMALL
		#define NR_BYTES	1
	#else
		#define NR_BYTES	(2*WIN_SZ)/8
	#endif	



	struct mytimer {
		unsigned char *open_pkts;
		unsigned char *bitstream;
		struct tasklet_hrtimer mytimer;
		struct sk_buff_head *stack_list;
		rwlock_t *tx_lock;
	};

	struct fb_crr_tx_priv {
		idp_t port[2];
		seqlock_t lock;
		rwlock_t tx_lock;
		struct mytimer my_timer[2*WIN_SZ];
		unsigned char *tx_open_pkts;
		unsigned char *tx_seq_nr;
		unsigned char *tx_win_nr;
		unsigned char *bitstream;
		unsigned char *wait_active;
		struct sk_buff_head *tx_stack_list;
		struct sk_buff_head *tx_queue_list;
	};

	//struct mytimer my_timer[2*WIN_SZ];

	/*
	 * Attention: Pos [1...32]
	 */

	/*static unsigned char bit_is_set(unsigned int *bitstream, unsigned char pos)
	{
		if (pos > 32) {
			//printk(KERN_ERR "Unvalid bit position for int\n");
			return 0;
		}

		if (*bitstream & (1<<(pos-1))) 
			return 1;
		else 
			return 0;

	}*/

	static unsigned char is_zero(unsigned char *arr)
	{
		int i;

		for (i = 0; i < NR_BYTES ; i++) {					// check if every byte is zero
			if (arr[i] != 0)						// byte not zero -> return 0
				return 0;
		}
		return 1;								// al bytes passed return 1
	}

	static struct sk_buff *skb_get_nr(unsigned char n, struct sk_buff_head *list)
	{

		struct sk_buff *curr = list->next;
		int i;
		for(i=0;i<5;i++){
                	printk(KERN_ERR "byte %d, value %x\n", i, curr->data[i]);
                }
		
		while (1) {
			if (*(curr->data) == n)
				return curr;
			else {
				if ((curr = curr->next) == (struct sk_buff *)list)
					return 0;
			}
			printk(KERN_ERR "in while %x\n", *(curr->data));
		}
	}

	/* Timeout:
	 * 1.) Get oldest packet from stack.
	 *	-> Fails: decrement pkt counter
	 * 2.) Clone it
	 *	-> Fails: decrement pkt counter
	 * 3.) Schedule the packet
	 * 4.) Restart the timer
	 */

	//static void fb_crr_tx_timeout(unsigned long args)
	static enum hrtimer_restart fb_crr_tx_timeout(struct hrtimer *self)
	{
		//cycles_t start, finish, diff;
		unsigned int queue_len;
		struct sk_buff *curr, *cloned_skb;
		//unsigned long flags;
		struct tasklet_hrtimer *thr = container_of(self, struct tasklet_hrtimer, timer);
		struct mytimer *timer = container_of(thr, struct mytimer, mytimer);
		//struct mytimer *timer = (struct mytimer *)args;

		
		write_lock_bh(timer->tx_lock);						// LOCK 
		//start = get_cycles();
			
		if (unlikely(*timer->open_pkts == 0)) {
			//printk(KERN_ERR "[TO]\tNo open packets\n");
			write_unlock_bh(timer->tx_lock);				// UNLOCK
			return HRTIMER_NORESTART;
		}

		if(unlikely(!(queue_len = skb_queue_len(timer->stack_list)))) {
			//BUG("[TO]\tBUG: Timeout with empty stack!\n");
			BUG();
			return HRTIMER_NORESTART;
		}
			
		curr = skb_dequeue(timer->stack_list);

		if (unlikely(curr == NULL)) {							// W send pkt again. first in list is oldest passed
			//printk(KERN_ERR "[TO]\tError: Stack is empty!\n"); 		// BUG should never happen!
			BUG();
			timer->open_pkts -=1;						// W 
			write_unlock_bh(timer->tx_lock);				// UNLOCKa
			return HRTIMER_NORESTART;
		}

		printk(KERN_ERR "[TO]\tOpen packet!\n"); 	

		if (likely((cloned_skb = skb_copy(curr, GFP_ATOMIC)))) {
			skb_queue_tail(timer->stack_list, curr);
			/* ACHTUNG!!! Vor process_packet muss ein rcu_read_lock() und
			 * danach ein rcu_read_unlock() gesetzt werden! */ 
			rcu_read_lock();
			process_packet(cloned_skb, TYPE_EGRESS);
			rcu_read_unlock();

			//engine_backlog_tail(cloned_skb, TYPE_EGRESS);
			//printk(KERN_ERR "[TO]\t\tResent Seq %d\tNr %d!\n", *(curr->data+ETH_HDR_LEN), *(curr->data+ETH_HDR_LEN+2));	
		}
		else {
			skb_queue_tail(timer->stack_list, curr);	
			//printk(KERN_ERR "[TO]\t\tError: Couldn't copy!\n");
			timer->open_pkts -=1;
		}

		//mod_timer(&timer->mytimer, jiffies + 10*HZ);				// restart timer 					// UNLOCKb
		tasklet_hrtimer_start(thr, ktime_set(0, 1000000000),			// 1 sec
				      HRTIMER_MODE_REL);
		

		//finish = get_cycles();
		//diff = (finish > start) ? finish-start : finish + (((unsigned long long)(0) - 1) - start);
		write_unlock_bh(timer->tx_lock);
		//printk(KERN_ERR "[TO]\tNr cycles: %lld\n", diff);
		return HRTIMER_NORESTART;
	}

	static int fb_crr_tx_netrx(const struct fblock * const fb,
				  struct sk_buff * const skb,
				  enum path_type * const dir)
	{
		int drop = 0;
		//cycles_t start, finish, diff;
		unsigned int queue_len;
		unsigned char seq, ack, currseq;
		//unsigned long flags;
		struct sk_buff *cloned_skb, *curr;
		struct fb_crr_tx_priv *fb_priv;

		//start = get_cycles();

		printk(KERN_ERR "fb_crr: fb_crr_tx_netrx called\n");
		printk(KERN_ERR "fb_crr: direction: %d, length: %d\n", *dir, skb->len);
		fb_priv = rcu_dereference_raw(fb->private_data);
	#ifdef __DEBUG
		//printk("Got skb on %p on ppe%d!\n", fb, smp_processor_id());
	#endif
		prefetchw(skb->cb);
		do {
			seq = read_seqbegin(&fb_priv->lock);
			write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
			if (fb_priv->port[*dir] == IDP_UNKNOWN)
				drop = 1;
		} while (read_seqretry(&fb_priv->lock, seq));

		if (*dir == TYPE_EGRESS ){ //&& ntohs(eth_hdr(skb)->h_proto) == 0xabba) {	// Send 

			write_lock_bh(&fb_priv->tx_lock);			// LOCK

			currseq = *fb_priv->tx_seq_nr; 				// R tag packet with seq nr 
			*fb_priv->tx_seq_nr = (*fb_priv->tx_seq_nr % (2*WIN_SZ)) + 1; // W Increment seq nr for next packet 
			//TODO: repoint skb->data to forward
			skb_push(skb,2); //allocate space for the header
			*(skb->data) = currseq;
			printk(KERN_ERR "fb_crr: sequence number: %d\n", currseq);
			if (currseq == 1)						// new window change 'ACK'
				*fb_priv->tx_win_nr = ~*fb_priv->tx_win_nr;// Invert ACK
			*(skb->data + 1) = *fb_priv->tx_win_nr;	// Tag ACK in packet		
			queue_len = skb_queue_len(fb_priv->tx_queue_list);	
			//printk(KERN_ERR "fb_crr: [TX]\tCurrseq: %d\tOpen_pkts: %d\tQlen: %d\n",
				//currseq, *fb_priv_cpu->tx_open_pkts, queue_len);

			if (queue_len == MAX_QUEUE_LEN && *fb_priv->wait_active == 0) {// in fact already 501 elements
				int one = 1;
				notify_fblock_subscribers((struct fblock *)fb, FBLOCK_WAIT, &one);
				*fb_priv->wait_active = 1;
				printk(KERN_ERR "fb_crr: [TX]\tWAIT ACTIVATED!\n");
			}
			else if (queue_len == MIN_QUEUE_LEN && *fb_priv->wait_active == 1) {
				int zero = 0;
				notify_fblock_subscribers((struct fblock *)fb, FBLOCK_WAIT, &zero);
				*fb_priv->wait_active = 0;
				printk(KERN_ERR "fb_crr: [TX]\tWAIT DEACTIVATED!\n");
			}

			if (likely(*fb_priv->tx_open_pkts == WIN_SZ )) {		// Queue packet

				printk(KERN_ERR "fb_crr: queued packet\n");
				skb_queue_tail(fb_priv->tx_queue_list, skb);// W
				//printk(KERN_ERR "[TX]\tAdded to queue %d\n", *(skb->data + ETH_HDR_LEN + 2)); 
				write_unlock_bh(&fb_priv->tx_lock);		// UNLOCKa
				drop = 2;
				//}
				/*else {
					write_unlock_bh(&fb_priv_cpu->tx_lock);	// UNLOCKb
					////printk(KERN_ERR "Send UNLOCKED!\n");
					//printk(KERN_ERR "[TX]\tQueue is full!\n");
					drop = 1;	
				}*/
			}
			else {								// FREE packets!
											
				if (unlikely(queue_len)) {				// Check if packets in queue need to be send first 
					skb_queue_tail(fb_priv->tx_queue_list, skb);// W Queue new packet at end of queue_list 
					curr = skb_dequeue(fb_priv->tx_queue_list);// W Dequeue first element of queue_list
					currseq = *(curr->data);		// Packet from queue -> new currseq

					if (currseq == 1 && is_zero(fb_priv->bitstream) == 0 ) { // Packet back in queue and dont send if new seq nr but bitstream not zero 
						skb_queue_head(fb_priv->tx_queue_list, curr);
						printk(KERN_ERR "fb_crr: [TX]\tMissing ACKS before starting new round!\n");
						printk(KERN_ERR "fb_crr: [TX]\tAdded to queue %d\n", *(skb->data  + 2)); 
						drop = 2;
						write_unlock_bh(&fb_priv->tx_lock);// UNLOCKc
						goto out;
					}
					if (likely((cloned_skb = skb_copy(curr, GFP_ATOMIC)))) { 
						skb_queue_tail(fb_priv->tx_stack_list, curr);// W Queue at end of stack_list 	
						rcu_read_lock();
						process_packet(cloned_skb, TYPE_EGRESS);// process packet
						rcu_read_unlock();			// idp and seq_nr should be correct. schedule for egress path
				
						(*fb_priv->tx_open_pkts)++;
						SETBIT(fb_priv->bitstream,(currseq-1)); // seq 1 <-> bit 0
						//*fb_priv_cpu->bitstream = SET_BIT(*fb_priv_cpu->bitstream, currseq);
						//*fb_priv_cpu->bitstream = *fb_priv_cpu->bitstream | (1<<(currseq-1)); // set bitstream				
						//printk(KERN_ERR "[TX]\t\tSent %d from queue\tNr %d\n", currseq, *(curr->data+ETH_HDR_LEN+2));			
						printk(KERN_ERR "fb_crr: sent packet\n");
					}
					else {
						skb_queue_tail(fb_priv->tx_stack_list, curr);// W Queue at end of stack_list 
						printk(KERN_ERR "fb_crr: [TX]\tError: Couldn't copy!\n");	
					}		
					drop = 2;					// don't send and don't free, because in list
				}
				else {							// send packet and push on stack 
				

					if (seq == 1 && is_zero(fb_priv->bitstream) == 0) { // Packet back in queue and dont send  
						skb_queue_head(fb_priv->tx_queue_list, skb);
						drop = 2;
						write_unlock_bh(&fb_priv->tx_lock);// UNLOCKc
						printk(KERN_ERR "fb_crr: [TX]\tMissing ACKS before starting new round!\n");
						//printk(KERN_ERR "fb_crr: [TX]\tAdded to queue %d\n", *(skb->data + ETH_HDR_LEN + 2)); 
						goto out;
					}

					if (likely((cloned_skb = skb_copy(skb, GFP_ATOMIC)))) { 	
						skb_queue_tail(fb_priv->tx_stack_list, cloned_skb);// W 
						(*fb_priv->tx_open_pkts)++;				// W
						SETBIT(fb_priv->bitstream,(currseq-1)); // seq 1 <-> bit 0
						//*fb_priv_cpu->bitstream = SET_BIT(*fb_priv_cpu->bitstream, currseq);
						//*fb_priv_cpu->bitstream = *fb_priv_cpu->bitstream | (1<<(currseq-1)); // set bitstream
						//printk(KERN_ERR "[TX]\t\tSent %d normal\tNr %d\n", currseq, *(skb->data+ETH_HDR_LEN+2)); 
						printk(KERN_ERR "fb_crr: [TX]\t\tSent %d normal\n", currseq);
					}
					else {
						drop = 1;
						write_unlock_bh(&fb_priv->tx_lock);// UNLOCKc
						printk(KERN_ERR "fb_crr: [TX]\t\tError: Couldn't copy!\n");
						goto out;
					}
				}

				//mod_timer(&my_timer[currseq-1].mytimer, jiffies + currseq*10*HZ); 
				tasklet_hrtimer_start(&fb_priv->my_timer[currseq-1].mytimer, ktime_set(0, 1000000000), // 1 sec
					      HRTIMER_MODE_REL);
				write_unlock_bh(&fb_priv->tx_lock);		// UNLOCKc

			}
		//finish = get_cycles();
		//diff = (finish > start) ? finish-start : finish + (((unsigned long long)(0) - 1) - start);
		//printk(KERN_ERR "[TX]\tNr cycles: %lld\n", diff);
		}
		/* Receive */
		else {//if (*dir == TYPE_INGRESS ){ //&& ntohs(eth_hdr(skb)->h_proto) == 0xabba) { // possible ACK 
			int i;
			printk(KERN_ERR "fb_crr: dir %d, TYPE_INGRESS: %d \n", *dir, TYPE_INGRESS);
			seq =  *skb->data;
			ack =  *(skb->data+1);
			for(i=0;i<32;i++){
				printk(KERN_ERR "byte %d, value %x\n", i, skb->data[i]);
			}	
			printk(KERN_ERR "end\n");		
	
			printk(KERN_ERR "fb_crr: received ack: seq: %d, ack %d\n", seq, ack);	
			if (unlikely(ack != 0xFF || seq == 0 || seq > 2*WIN_SZ))	// invalid packets
				goto out;

			write_lock_bh(&fb_priv->tx_lock);			// LOCK
			printk(KERN_ERR "fb_crr: [RX]\tACK received\n");

			/*if (likely(!bit_is_set(fb_priv_cpu->bitstream, seq))) {
				write_unlock_bh(&fb_priv_cpu->tx_lock);
				goto out;
			}*/
	
			tasklet_hrtimer_cancel(&fb_priv->my_timer[seq-1].mytimer);
			(*fb_priv->tx_open_pkts)--;				// W 

			//printk(KERN_ERR "[RX]\tACK %d with %d\tOpenpkts: %d\n", seq,
			//*(skb->data+2) ,*fb_priv_cpu->tx_open_pkts);

			if (likely((curr = skb_get_nr(seq, fb_priv->tx_stack_list)))) {	// R get according element 
				printk(KERN_ERR "fb_crr: [RX]\tACK Seq %d Nr %d\n", seq, *(skb->data+2));			
				skb_unlink(curr, fb_priv->tx_stack_list);		// W dequeue from list 
				kfree(curr);
			}
			printk(KERN_ERR "fb_crr: [RX]\tACK received 2 \n");

			drop = 1;							// drop pkt before user space
			CLEARBIT(fb_priv->bitstream, (seq-1));
			//write_unlock_bh(&fb_priv->tx_lock);  	
			//goto out;						
			//*fb_priv_cpu->bitstream = UNSET_BIT(*fb_priv_cpu->bitstream, seq);
			//printk(KERN_ERR "[RX]\tBitstream new: %d\n", *fb_priv_cpu->bitstream);

ACK_SEND:

			queue_len = skb_queue_len(fb_priv->tx_queue_list);

			if (queue_len == MIN_QUEUE_LEN && *fb_priv->wait_active == 1) {
				int zero = 0;
				notify_fblock_subscribers((struct fblock *)fb, FBLOCK_WAIT, &zero);
				*fb_priv->wait_active = 0;
				printk(KERN_ERR "fb_crr: [RX]\tWAIT DEACTIVATED!\n");
			}

			if (likely(queue_len)) {					// && *fb_priv_cpu->tx_open_pkts <= MAX_OPEN_PKTS) {  R 
				curr = skb_dequeue(fb_priv->tx_queue_list);	// W Dequeue first element of queue_list
				seq = *(curr->data); //+ETH_HDR_LEN);

				if (seq == 1 && is_zero(fb_priv->bitstream) == 0) { // Packet back in queue and dont send  
					skb_queue_head(fb_priv->tx_queue_list, curr);
					write_unlock_bh(&fb_priv->tx_lock);	// UNLOCKc
					printk(KERN_ERR "fb_crr: [RX]\tMissing ACKS before starting new round!\n");
					goto out;
				}

				if (likely((cloned_skb = skb_copy(curr, GFP_ATOMIC))))  {
					skb_queue_tail(fb_priv->tx_stack_list, curr);// W Queue at end of stack_list 			
					//printk(KERN_ERR "[RX-ACK]\t\tSent Seq %d\tNr %d\n", *(curr->data+ETH_HDR_LEN), *(curr->data+ETH_HDR_LEN+2));
					rcu_read_lock();
					process_packet(cloned_skb, TYPE_EGRESS);
					rcu_read_unlock();	// idp and seq_nr should be correct. schedule for egress path
				
					(*fb_priv->tx_open_pkts)++; 
					SETBIT(fb_priv->bitstream,(seq-1)); // seq 1 <-> bit 0
					//*fb_priv_cpu->bitstream = SET_BIT(*fb_priv_cpu->bitstream, seq);
					//printk(KERN_ERR "[RX]\tBitstream new: %d\n", *fb_priv_cpu->bitstream);
					tasklet_hrtimer_start(&fb_priv->my_timer[seq-1].mytimer, ktime_set(0, 1000000000), // 1 sec
						      HRTIMER_MODE_REL);  
					if (*fb_priv->tx_open_pkts < WIN_SZ)	// W
						goto ACK_SEND;
				}
				else {
					skb_queue_tail(fb_priv->tx_stack_list, curr);// W Queue at end of stack_list
					tasklet_hrtimer_start(&fb_priv->my_timer[seq-1].mytimer, ktime_set(0, 1000000000), // 1 sec
						      HRTIMER_MODE_REL);
					//printk(KERN_ERR "[RX]\t\tError: Couldn't copy!\n");
				}
			}
			else {
				//printk(KERN_ERR "[TX-ACK]\t\tError: Queue empty!\n");	
			}

			write_unlock_bh(&fb_priv->tx_lock);				
			//printk(KERN_ERR "Receive UNLOCKED!\n");
			//finish = get_cycles();
			//diff = (finish > start) ? finish-start : finish + (((unsigned long long)(0) - 1) - start);
			//printk(KERN_ERR "[ACK]\tNr cycles: %lld\n", diff);
		}
out:
		if (drop == 1) {
			kfree_skb(skb);
			printk(KERN_ERR "fb_crr: Freed and dropped!\n");
			return PPE_DROPPED;
		}
		else if (drop == 2) {
			printk(KERN_ERR "fb_crr: Dropped!\n");
			return PPE_DROPPED;
		}
		printk(KERN_ERR "fb_crr: Passed on!\n");
		return PPE_SUCCESS;
	}

static int fb_crr_tx_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_crr_tx_priv *fb_priv;

	rcu_read_lock();
	fb = rcu_dereference_raw(container_of(self, struct fblock_notifier, nb)->self);
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	switch (cmd) {
	case FBLOCK_BIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == IDP_UNKNOWN) {
			write_seqlock(&fb_priv->lock);
			fb_priv->port[msg->dir] = msg->idp;
			write_sequnlock(&fb_priv->lock);
		} else {
			ret = NOTIFY_BAD;
		}
		} break;
	case FBLOCK_UNBIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == msg->idp) {
			write_seqlock(&fb_priv->lock);
			fb_priv->port[msg->dir] = IDP_UNKNOWN;
			write_sequnlock(&fb_priv->lock);
		} else {
			ret = NOTIFY_BAD;
		}
		} break;
	default:
		break;
	}

	return ret;
}

static struct fblock *fb_crr_tx_ctor(char *name)
{
	int ret = 0;
	unsigned char *tmp_open_pkts, *tmp_seq_nr, *tmp_win_nr, *tmp_wait_active;
	unsigned char *tmp_bitstream;
	unsigned int i;
	struct sk_buff_head *tmp_stack_list, *tmp_queue_list;
	struct fblock *fb;
	struct fb_crr_tx_priv *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;

	tmp_wait_active = kzalloc(sizeof(unsigned char), GFP_ATOMIC);
	if (unlikely(!tmp_wait_active)) 
		goto err_;

	fb_priv = kzalloc(sizeof(struct fb_crr_tx_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;


	if (unlikely((tmp_open_pkts = kzalloc(sizeof(unsigned char), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto erra;
	}

	if (unlikely((tmp_seq_nr = kzalloc(sizeof(unsigned char), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto errb;
	}

	if (unlikely((tmp_bitstream = kzalloc((NR_BYTES)*sizeof(unsigned char), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto err0;
	}

	if (unlikely((tmp_stack_list = kzalloc(sizeof(struct sk_buff_head), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto err1;
	}

	if (unlikely((tmp_win_nr = kzalloc(sizeof(struct sk_buff_head), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto err1_;
	}

	if (unlikely((tmp_queue_list = kzalloc(sizeof(struct sk_buff_head), GFP_ATOMIC)) == NULL)) {
		//printk(KERN_ERR "Allocation failed!\n");
		goto err1a;
	}

	*tmp_win_nr = 0;
	*tmp_open_pkts = 0;
	*tmp_bitstream = 0;
	*tmp_seq_nr = 1;
	*tmp_wait_active = 0;

	skb_queue_head_init(tmp_stack_list);
	skb_queue_head_init(tmp_queue_list);

	/*for (i = 0; i < 2*WIN_SZ; i++) {
		tasklet_hrtimer_init(&priv->my_timer[i].mytimer,
				     fb_crr_tx_timeout,
				     CLOCK_REALTIME, HRTIMER_MODE_ABS);		
		priv->my_timer[i].open_pkts = tmp_open_pkts;
		priv->my_timer[i].stack_list = tmp_stack_list;
		priv->my_timer[i].bitstream = tmp_bitstream;
	}*/

	seqlock_init(&fb_priv->lock);
	rwlock_init(&fb_priv->tx_lock);

	for (i = 0; i < 2*WIN_SZ; i++) {
		tasklet_hrtimer_init(&fb_priv->my_timer[i].mytimer,
				     fb_crr_tx_timeout,
				     CLOCK_REALTIME, HRTIMER_MODE_ABS);		
		fb_priv->my_timer[i].open_pkts = tmp_open_pkts;
		fb_priv->my_timer[i].stack_list = tmp_stack_list;
		fb_priv->my_timer[i].bitstream = tmp_bitstream;
		fb_priv->my_timer[i].tx_lock = &fb_priv->tx_lock;
	}
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->tx_open_pkts = tmp_open_pkts;
	fb_priv->tx_seq_nr = tmp_seq_nr;
	fb_priv->tx_win_nr = tmp_win_nr;
	fb_priv->bitstream = tmp_bitstream;
	fb_priv->tx_stack_list = tmp_stack_list;
	fb_priv->tx_queue_list = tmp_queue_list;
	fb_priv->wait_active = tmp_wait_active;

	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_crr_tx_netrx;
	fb->event_rx = fb_crr_tx_event;
	ret = register_fblock_namespace(fb);
	if (ret)
		goto err3;
	__module_get(THIS_MODULE);
	//printk(KERN_ERR "[CRR TX] Initialization passed!\n");
	return fb;
err3:
	cleanup_fblock_ctor(fb);
err2:
	for (i = 0; i < 2*WIN_SZ; i++) 
		tasklet_hrtimer_cancel(&fb_priv->my_timer[i].mytimer);
	kfree(tmp_queue_list);
err1a:
	kfree(tmp_win_nr);
err1_:
	kfree(tmp_stack_list);
err1:
	kfree(tmp_bitstream);
err0:
	kfree(tmp_seq_nr);
errb:
	kfree(tmp_open_pkts);	
erra:
	kfree(fb_priv);
err:
	kfree(tmp_wait_active);
err_:
	kfree_fblock(fb);
	return NULL;
}

static void fb_crr_tx_dtor(struct fblock *fb)
{
	int i, queue_len;
	//unsigned long flags;
	struct fb_crr_tx_priv *fb_priv;
	struct sk_buff *tmp_skb;

	//printk(KERN_ERR "[CRR TX] Deinit Start!\n");

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	write_lock_bh(&fb_priv->tx_lock);					/* LOCK */
	//printk(KERN_ERR "[CRR TX] Deinit LOCKED!\n");

	for (i = 0; i < 2*WIN_SZ; i++)
		tasklet_hrtimer_cancel(&fb_priv->my_timer[i].mytimer);
	//printk(KERN_ERR "[CRR TX] Deinit Timers stopped\n");

	queue_len = skb_queue_len(fb_priv->tx_stack_list);
	//printk(KERN_ERR "[CRR TX] Deinit Qlen stack: %d\n", queue_len);

	for (i = 0; i < queue_len; i++) {					/* delete remaining elements in stack list */
		tmp_skb = skb_dequeue(fb_priv->tx_stack_list);
		kfree(tmp_skb);
	}
	//printk(KERN_ERR "[CRR TX] Deinit Qlen queue: %d\n", queue_len);
	queue_len = skb_queue_len(fb_priv->tx_queue_list);

	for (i = 0; i < queue_len; i++) {					/* delete remaining elements in queue list */
		tmp_skb = skb_dequeue(fb_priv->tx_queue_list);		
		kfree(tmp_skb);
	}
	//printk(KERN_ERR "[CRR TX] Deinit Queues cleaned\n");

	kfree(fb_priv->tx_stack_list);
	kfree(fb_priv->tx_queue_list);
	//printk(KERN_ERR "[CRR TX] Deinit lists freed\n");

	kfree(fb_priv->tx_open_pkts);
	kfree(fb_priv->tx_seq_nr);
	kfree(fb_priv->tx_win_nr);
	kfree(fb_priv->bitstream);
	//printk(KERN_ERR "[CRR TX] Deinit pkts, bitstream and seq freed\n");

	kfree(fb_priv->wait_active);
	//printk(KERN_ERR "[CRR TX] Deinit wait_active freed\n");

	write_unlock_bh(&fb_priv->tx_lock);					// UNLOCK
	//printk(KERN_ERR "[CRR TX] Deinit UNLOCKED!\n");

	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
	//printk(KERN_ERR "[CRR TX] Deinitialization passed!\n");
}

static struct fblock_factory fb_crr_tx_factory = {
	.type = "ch.ethz.csg.crr",
	.mode = MODE_DUAL,
	.ctor = fb_crr_tx_ctor,
	.dtor = fb_crr_tx_dtor,
	.owner = THIS_MODULE,
	.properties = {RELIABLE}
};

static int __init init_fb_crr_tx_module(void)
{
	return register_fblock_type(&fb_crr_tx_factory);
}

static void __exit cleanup_fb_crr_tx_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_crr_tx_factory);
}

module_init(init_fb_crr_tx_module);
module_exit(cleanup_fb_crr_tx_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Florian Deragisch <floriade@ee.ethz.ch>");
MODULE_DESCRIPTION("LANA CRR tx module");
