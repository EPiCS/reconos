/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* e.g. dd if=/dev/urandom of=/proc/net/lana/fblock/fb0 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/prefetch.h>
#include <linux/slab.h>
#include <linux/seq_file.h>

#include "xt_fblock.h"
#include "xt_engine.h"
#include "rijndael.h"

struct fb_aes_priv {
	idp_t port[2];
	seqlock_t lock;
	uint8_t *key;
	uint8_t key_bits;
	int nrounds;
	size_t len;
	unsigned long *rk;
	rwlock_t klock;
} ____cacheline_aligned_in_smp;


static int fb_aes_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	unsigned int seq;
	unsigned int padding;
	struct fb_aes_priv *fb_priv;
	size_t i = 0;
	unsigned char ciphertext[16];
	//we don't have jumbo packets.	
	u16 pktlen = (u16)skb->len;
	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			goto drop;
	} while (read_seqretry(&fb_priv->lock, seq));

	read_lock(&fb_priv->klock);
	
	//we need to pad to 16 bytes
	//for hardware compatability this is done by setting the last two bytes to the actual packet len.
	//reserve space for the padding:
	skb_put(skb,2);
	//reserve space for the padding
	padding = skb->len % 16;
	skb_put(skb, padding);
	//write len to buffer
	memcpy(&skb->data[skb->len - 2], &pktlen, 2);
//	skb->data[skb->len - 1] = (unsigned char) padding; //last byte is amount of padding;
	
	//here we do the encryption
	for (i = 0; i < skb->len; i += 16){
		rijndaelEncrypt(fb_priv->rk, fb_priv->nrounds, skb->data + i, ciphertext);
		memcpy(skb->data + i, ciphertext, 16);
	}

	read_unlock(&fb_priv->klock);

	return PPE_SUCCESS;
drop:
	printk(KERN_INFO "[fb_aes] drop packet. Unknown IDP\n");
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_aes_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_aes_priv *fb_priv;

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
		break; }
	case FBLOCK_UNBIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == msg->idp) {
			write_seqlock(&fb_priv->lock);
			fb_priv->port[msg->dir] = IDP_UNKNOWN;
			write_sequnlock(&fb_priv->lock);
		} else {
			ret = NOTIFY_BAD;
		}
		break; }
	default:
		break;
	}

	return ret;
}

static int fb_aes_proc_show(struct seq_file *m, void *v)
{
	struct fblock *fb = (struct fblock *) m->private;
	struct fb_aes_priv *fb_priv;
	char sline[64];

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	memset(sline, 0, sizeof(sline));

	read_lock(&fb_priv->klock);
	snprintf(sline, sizeof(sline), "%d\n", (fb_priv->key_bits));
	read_unlock(&fb_priv->klock);

	seq_puts(m, sline);
	return 0;
}

static int fb_aes_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, fb_aes_proc_show, PDE(inode)->data);
}

static ssize_t fb_aes_proc_write(struct file *file, const char __user * ubuff,
				 size_t count, loff_t * offset)
{
	struct fblock *fb = PDE(file->f_path.dentry->d_inode)->data;
	struct fb_aes_priv *fb_priv;

	if (count != 16 && count != 24 && count != 32){
		printk(KERN_ERR "invalid key length %d\n", count);
		return -EINVAL;
	}

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	write_lock(&fb_priv->klock);

	if (copy_from_user(fb_priv->key, ubuff, count)) {
		printk(KERN_ERR "could not copy user buffer\n");
		return -EIO;
	}

	//setup key
	printk(KERN_ERR "count %d\n", count);
	fb_priv->key_bits = count * 8;
	printk(KERN_ERR "key_bits %d\n", fb_priv->key_bits);

	fb_priv->rk = kmalloc(RKLENGTH(fb_priv->key_bits)*sizeof(long), GFP_KERNEL);
	fb_priv->nrounds = rijndaelSetupEncrypt(fb_priv->rk, fb_priv->key, fb_priv->key_bits);	
	
	write_unlock(&fb_priv->klock);

	return count;
}

static const struct file_operations fb_aes_proc_fops = {
	.owner   = THIS_MODULE,
	.open    = fb_aes_proc_open,
	.read    = seq_read,
	.llseek  = seq_lseek,
	.write   = fb_aes_proc_write,
	.release = single_release,
};

static struct fblock *fb_aes_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_aes_priv *fb_priv;
	struct proc_dir_entry *fb_proc;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	rwlock_init(&fb_priv->klock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;

	fb_priv->key = kmalloc(32, GFP_KERNEL); //max key size
	if (!fb_priv->key)
		goto err1;
	fb_priv->len = 0;

	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;

	fb->netfb_rx = fb_aes_netrx;
	fb->event_rx = fb_aes_event;
//	fb->linearize = fb_aes_linearize;
//	fb->delinearize = fb_aes_delinearize;
	fb_proc = proc_create_data(fb->name, 0444, fblock_proc_dir,
				   &fb_aes_proc_fops, (void *)(long) fb);
	if (!fb_proc)
		goto err3;

	ret = register_fblock_namespace(fb);
	if (ret)
		goto err4;

	__module_get(THIS_MODULE);

	return fb;
err4:
	remove_proc_entry(fb->name, fblock_proc_dir);
err3:
	cleanup_fblock_ctor(fb);
err2:
	kfree(fb_priv->key);
err1:
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	return NULL;
}

static void fb_aes_dtor_outside_rcu(struct fblock *fb)
{
	kfree(((struct fb_aes_priv *)rcu_dereference_raw(fb->private_data))->key);
}

static void fb_aes_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	remove_proc_entry(fb->name, fblock_proc_dir);
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_aes_factory = {
	.type = "ch.ethz.csg.aes",
	.mode = MODE_DUAL,
	.ctor = fb_aes_ctor,
	.dtor = fb_aes_dtor,
	.dtor_outside_rcu = fb_aes_dtor_outside_rcu,
	.owner = THIS_MODULE,
	.properties = { [0] = "privacy" },
};

static int __init init_fb_aes_module(void)
{
	return register_fblock_type(&fb_aes_factory);
}

static void __exit cleanup_fb_aes_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_aes_factory);
}

module_init(init_fb_aes_module);
module_exit(cleanup_fb_aes_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ariane Keller <ariane.keller@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA AES module. It uses the original rijndael implementation.");
