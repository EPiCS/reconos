/*
 * Lightweight Autonomic Network Architecture
 *
 * crr_rx test module.
 *
 * Copyright 2011 Florian Deragisch <floriade@ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

/*
 * ETH_TYPE | SEQ_NR | ACK|
 *
 * WIN >= 4 !
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

#include "xt_fblock.h"
#include "xt_engine.h"

#define ETH_HDR_LEN	0
#define WIN_SZ		2
#define WIN_SZ_SMALL								//for WIN_SZ < 4
#define BIT_FULL	(1 << (2*WIN_SZ)) - 1

#ifdef WIN_SZ_SMALL
	#define NR_BYTES	1
#else
	#define NR_BYTES	(2*WIN_SZ)/8
#endif

struct fb_crr_rx_priv {
	idp_t port[2];
	seqlock_t lock;
	rwlock_t *rx_lock;
	unsigned char *rx_win_nr;
	unsigned char *rx_seq_nr;
	unsigned char *rx_bitstream;
	struct sk_buff_head *list;
};

static unsigned char set_bit_pos(unsigned char *bitstream, unsigned char pos)
{
	if ((bitstream[pos>>3] & (1 << (pos&7))))				/* bit is set */
		return 0;
	else {									/* bit is not set */
		bitstream[pos>>3] |= (1 << (pos&7));
		//if (*bitstream == BIT_FULL)					/* all Seq nr received */
		//	*bitstream = 0;						/* reset and start new round ==> Bitstream muss vom neuen Window Reseted werden */
		return 1;
	}

}

static void set_zero(unsigned char *arr) 
{
	int i;
	
	for (i = 0; i < NR_BYTES; i++)
		arr[i] = 0;
}


/* returns a pointer to the skb_buff with the according seq number */
static struct sk_buff *skb_get_pos(unsigned char seq, struct sk_buff_head *list)
{
	struct sk_buff *curr = list->next;

	if (list->next == (struct sk_buff *)list) {				/* list is empty */
		printk(KERN_ERR "fb_crr: List is empty\n");		
		return list->next;
	}
	
	else if (seq == 2) {							/* Second element */
		printk(KERN_ERR "fb_crr: Seqnr 2 -> First element\n");
		return list->next;
	}	
		
	while(1) {								/* Others */
		if (*(curr->data + ETH_HDR_LEN) > seq)
			break;
		else if (*(curr->data + ETH_HDR_LEN) == seq) {		/* identical copy */
			printk(KERN_ERR "fb_crr: Identical copy exists\n");
			return 0;
		}
	
		if (curr->next == (struct sk_buff *)list) {
			printk(KERN_ERR "fb_crr: Reached end of the list\n");
			return (struct sk_buff *)list;
		}
		curr = curr->next;
	}
	return curr;
}

static int fb_crr_rx_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	int drop = 0;
	unsigned int i, queue_len;
	unsigned char mac_src[6];
	unsigned char mac_dst[6];
	unsigned char seq, win_nr;
	struct sk_buff *skb_last, *cloned_skb;
	struct fb_crr_rx_priv *fb_priv;

	printk(KERN_ERR "fb_crr: fb_crr_rx_netrx called\n");
	fb_priv = rcu_dereference_raw(fb->private_data);
	
	printk("Got skb on %p fb_priv %p!\n", fb, fb_priv);
	
	prefetchw(skb->cb);
	do {
		printk(KERN_ERR "fb_crr: --- in do while \n");
		seq = read_seqbegin(&fb_priv->lock);			// LOCK
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		printk(KERN_ERR "fb_crr: --- fb->idp %d, fb_priv->port[*dir] %d dir %d \n", fb->idp, fb_priv->port[*dir], *dir);
		if (fb_priv->port[*dir] == IDP_UNKNOWN){
			printk(KERN_ERR "fb_crr: no idp specified\n");
			drop = 1;
		}
	} while (read_seqretry(&fb_priv->lock, seq));			// UNLOCK
	/* Send */

	if (*dir == TYPE_EGRESS){ // && ntohs(eth_hdr(skb)->h_proto) == 0xabba) {
		printk(KERN_ERR "fb_crr: should not be an egress packet...\n");
	}
	/* Receive */
	else if (*dir == TYPE_INGRESS){ // && ntohs(eth_hdr(skb)->h_proto) == 0xabba) {
		int i = 0;
		cloned_skb = NULL;
		for(i = 0;i<10; i++){
			printk(KERN_ERR "crr: %d -> %x\n", i, skb->data[i]);
		}			

		seq = *(skb->data); //*(skb->data + ETH_HDR_LEN);
		win_nr = *(skb->data + 1); //*(skb->data + ETH_HDR_LEN+1);
		printk(KERN_ERR "fb_crr: Received seq %d, win_nr %d\n", seq, win_nr);
		write_lock(fb_priv->rx_lock);
		if (win_nr != *fb_priv->rx_win_nr) {			// new window
			set_zero(fb_priv->rx_bitstream);			// Reset bitstream for new window
			*fb_priv->rx_win_nr = win_nr;
			printk(KERN_ERR "fb_crr: New window detected\n");	
		}				
		//printk(KERN_ERR "Expected: %d\t Received: %d Nr: %d\n", *fb_priv->rx_seq_nr, seq, *(skb->data + ETH_HDR_LEN+2));	
		if (likely(seq == *fb_priv->rx_seq_nr)) {
			printk(KERN_ERR "fb_crr: Correct Seqnr: %d\n", seq);		/* R Correct sequence number: */
			*fb_priv->rx_seq_nr = (*fb_priv->rx_seq_nr % (2*WIN_SZ)) + 1; // Add for correct packet
			queue_len = skb_queue_len(fb_priv->list);
			printk(KERN_ERR "fb_crr: Qlen: %d\n", queue_len);
			if(unlikely(!set_bit_pos(fb_priv->rx_bitstream, seq-1)))
				printk(KERN_ERR "fb_crr: There is a Bug!\n");
			printk(KERN_ERR "fb_crr: Passed Seq %d Queuelen %d\n",*(skb->data), queue_len);		
			for (i = 1; i <= queue_len; i++) { 			/* R iterate over nr elements in queue */
				printk(KERN_ERR "%d\n", i);
				skb_last = skb_peek(fb_priv->list);
				
				//printk(KERN_ERR "First Seqnr in Queue %d Nr %d\n", *(skb_last->data + ETH_HDR_LEN), *(skb_last->data + ETH_HDR_LEN+2));
				if (*(skb_last->data) == (seq % (2*WIN_SZ)) + i) {
					//printk(KERN_ERR "Send following Seqnr: %d\n", (seq % (2*WIN_SZ)) + i);
					skb_last = skb_dequeue(fb_priv->list);/* Remove first element in list */
					rcu_read_lock();
					//printk(KERN_ERR "Passed Seq %d Nr %d\n", *(skb_last->data + ETH_HDR_LEN), *(skb_last->data + ETH_HDR_LEN+2));
					process_packet(skb_last, *dir);		/* Send towards user space */
					rcu_read_unlock();
					*fb_priv->rx_seq_nr = (*fb_priv->rx_seq_nr % (2*WIN_SZ)) + 1; // add for each following packet that's correct
				}
				else {
					//printk(KERN_ERR "Following Seqnr not found: %d\n", (seq % (2*WIN_SZ)) + i);	/* if next missing -> break */
					break;
				}	
			}
			printk(KERN_ERR "fb_crr: Next Seqnr expected: %d\n", *fb_priv->rx_seq_nr);
			write_unlock(fb_priv->rx_lock);			// UNLOCK
		}
		else {
			printk(KERN_ERR "fb_crr: Wrong Seqnr: %d\n", seq);		/* Wrong Seq number -> keep in buffer */
			if (likely(set_bit_pos(fb_priv->rx_bitstream, seq-1))) {	/* New packet -> pass */
				if (!(skb_last = skb_get_pos(seq, fb_priv->list))) {
					write_unlock(fb_priv->rx_lock);		// UNLOCK
					//printk(KERN_ERR "DROP!\n");
					drop = 1;
					goto ACK;
				}
				skb_insert(skb_last, skb, fb_priv->list); 	/* W insert to position */
				queue_len = skb_queue_len(fb_priv->list);
				seq = *fb_priv->rx_seq_nr;
				//printk(KERN_ERR "New queuelen %d Expected %d\n", queue_len, seq);
				for (i = 0; i < queue_len; i++) { 			/* R iterate over nr elements in queue */
					//printk(KERN_ERR "%d\n", i);
					skb_last = skb_peek(fb_priv->list);
					//printk(KERN_ERR "First Seqnr in Queue %d Nr %d\n", *(skb_last->data + ETH_HDR_LEN), *(skb_last->data + ETH_HDR_LEN+2));
					if (*(skb_last->data) == (seq % (2*WIN_SZ)) + i) {
						//printk(KERN_ERR "Send following Seqnr: %d\n", (seq % (2*WIN_SZ)) + i);
						skb_last = skb_dequeue(fb_priv->list);/* Remove first element in list */
						rcu_read_lock();
						//printk(KERN_ERR "Passed %d\n", *(skb_last->data + ETH_HDR_LEN+2));
						process_packet(skb_last, *dir);		/* Send towards user space */
						rcu_read_unlock();
						*fb_priv->rx_seq_nr = (*fb_priv->rx_seq_nr % (2*WIN_SZ)) + 1;
					}
					else {
						//printk(KERN_ERR "Following Seqnr not found: %d\n", (seq % (2*WIN_SZ)) + i);	/* if next missing -> break */
						break;
					}	
				}


				//printk(KERN_ERR "Added New Qlen: %d\n", queue_len);
				write_unlock(fb_priv->rx_lock);		// UNLOCK
				drop = 2;
			}
			else {
				printk(KERN_ERR "fb_crr: Old packet!\n");		/* Old packet -> drop */
				//printk(KERN_ERR "DROP!\n");
				write_unlock(fb_priv->rx_lock);		// UNLOCK
				drop = 1;					/* Received packet for second time */
			}
		}
		skb_pull(skb, 2);
		printk(KERN_ERR "fb_crr: Send ACK!\n");
		goto ACK;
	}
	else {									// For now to make testing easier
		drop = 1;
	}
back:	
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
	printk(KERN_ERR "seq %d, testnumber: %d\n", seq, skb->data[1]);
	return PPE_SUCCESS;
ACK:
	if ((cloned_skb = skb_copy(skb, GFP_ATOMIC))) {				// skb_copy_expand(skb, 14, 0, GFP_ATOMIC)
		printk(KERN_ERR "fb_crr: in ACK\n");
		skb_push(cloned_skb, 2);
		//skb_set_mac_header(cloned_skb, -14);

		/*for (i = 0; i < 20; i++)
			//printk(KERN_ERR "%d\t0x%2x\n", i, *(skb->data-14+i));	
		
		for (i = 0; i < 20; i++)
			//printk(KERN_ERR "%d\t0x%2x\n", i, *(cloned_skb->data-14+i));*/
							
		//memcpy(mac_src, eth_hdr(cloned_skb)->h_source, 6);		/* Swap MAC Addresses */
		//memcpy(mac_dst, eth_hdr(cloned_skb)->h_dest, 6);
		//memcpy(eth_hdr(cloned_skb)->h_source, mac_dst, 6);
		//memcpy(eth_hdr(cloned_skb)->h_dest, mac_src, 6);
										
		//*(cloned_skb->data + ETH_HDR_LEN + 14) = seq;			/* Seq nummer bleibt die gleiche */
		*(cloned_skb->data + 1) = 0xFF;

		skb_trim(cloned_skb, 37);	//why 37? (most likely hash)				// Set to minimal size
										/* change idp order */
		read_lock(fb_priv->rx_lock);				// LOCK		
		write_next_idp_to_skb(cloned_skb, fb_priv->port[TYPE_EGRESS], fb->idp); /* R on port */
		read_unlock(fb_priv->rx_lock);				// UNLOCK
		rcu_read_lock();		
		process_packet(cloned_skb, TYPE_EGRESS);			/* schedule packet */
		rcu_read_unlock();
		printk(KERN_ERR "fb_crr: Send ACK done!\n");	
	}
	goto back;

}

static int fb_crr_rx_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_crr_rx_priv *fb_priv;

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

static struct fblock *fb_crr_rx_ctor(char *name)
{
	int ret = 0;
	unsigned char *tmp_expected_seq_nr, *tmp_rx_win_nr, *tmp_rx_bitstream;
	struct sk_buff_head *tmp_list;
	struct fblock *fb;
	struct fb_crr_rx_priv *fb_priv;
	rwlock_t *tmp_rx_lock;

	

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;


	fb_priv = kzalloc(sizeof(struct fb_crr_rx_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;

	if (unlikely((tmp_rx_bitstream = kzalloc((NR_BYTES)*sizeof(unsigned char), GFP_ATOMIC)) == NULL))
		goto err_;

	if (unlikely((tmp_rx_win_nr = kzalloc(sizeof(unsigned char), GFP_ATOMIC)) == NULL))
		goto err__;

	if (unlikely((tmp_rx_lock = kzalloc(sizeof(rwlock_t), GFP_ATOMIC)) == NULL))
		goto err0;

	if (unlikely((tmp_list = kzalloc(sizeof(struct sk_buff_head), GFP_ATOMIC)) == NULL))
		goto err1;

	if (unlikely((tmp_expected_seq_nr = kzalloc(sizeof(unsigned char), GFP_ATOMIC)) == NULL))
		goto err1a;
	
	rwlock_init(tmp_rx_lock);

	*tmp_rx_bitstream = 0;
	*tmp_rx_win_nr = 0;

	*tmp_expected_seq_nr = 1;
	
	skb_queue_head_init(tmp_list);

	seqlock_init(&fb_priv->lock);
	//rwlock_init(&fb_priv_cpu->rx_lock);
	fb_priv->rx_lock = tmp_rx_lock;		
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->rx_seq_nr = tmp_expected_seq_nr;
	fb_priv->list = tmp_list;
	fb_priv->rx_bitstream = tmp_rx_bitstream;
	fb_priv->rx_win_nr = tmp_rx_win_nr;

	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_crr_rx_netrx;
	fb->event_rx = fb_crr_rx_event;
	ret = register_fblock_namespace(fb);
	if (ret)
		goto err3;
	__module_get(THIS_MODULE);
	//printk(KERN_ERR "[CRR_RX] Initialization passed!\n");
	return fb;
err3:
	cleanup_fblock_ctor(fb);
err2:
	kfree(tmp_expected_seq_nr);
err1a:
	kfree(tmp_list);
err1:
	kfree(tmp_rx_lock);
err0:
	kfree(tmp_rx_win_nr); 
err__:
	kfree(tmp_rx_bitstream);
err_:
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	//printk(KERN_ERR "[CRR_RX] Initialization failed!\n");
	return NULL;
}

static void fb_crr_rx_dtor(struct fblock *fb)
{
	int i, queue_len;
	struct sk_buff *skb_last;
	struct fb_crr_rx_priv *fb_priv;
	//printk(KERN_ERR "[CRR_RX] Deinitialization 1!\n");

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();
	//printk(KERN_ERR "[CRR_RX] Deinitialization 2!\n");

	write_lock(fb_priv->rx_lock);					// LOCK
	queue_len = skb_queue_len(fb_priv->list);
	//printk(KERN_ERR "[CRR_RX] Deinitialization Qlen: %d!\n", queue_len);
	for (i = 0; i < queue_len; i++) {
		skb_last = skb_dequeue(fb_priv->list);
		kfree(skb_last);
	}
	kfree(fb_priv->list);
	kfree(fb_priv->rx_seq_nr);
	kfree(fb_priv->rx_win_nr);
	kfree(fb_priv->rx_bitstream);
	write_unlock(fb_priv->rx_lock);					// UNLOCK

	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
	//printk(KERN_ERR "[CRR_RX] Deinitialization passed!\n");
}

static struct fblock_factory fb_crr_rx_factory = {
	.type = "ch.ethz.csg.crr",
	.mode = MODE_DUAL,
	.ctor = fb_crr_rx_ctor,
	.dtor = fb_crr_rx_dtor,
	.owner = THIS_MODULE,
	.properties = {RELIABLE}
};

static int __init init_fb_crr_rx_module(void)
{
	return register_fblock_type(&fb_crr_rx_factory);
}

static void __exit cleanup_fb_crr_rx_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_crr_rx_factory);
}

module_init(init_fb_crr_rx_module);
module_exit(cleanup_fb_crr_rx_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Florian Deragisch <floriade@ee.ethz.ch>");
MODULE_DESCRIPTION("LANA CRR RX module");
