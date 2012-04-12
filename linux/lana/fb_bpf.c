/*
 * To generate BPF's, do the following:
 * 1. Install flex + bison
 * 2. Download bpfc from http://netsniff-ng.org i.e.:
 *    cd /tmp
 *    git clone git://repo.or.cz/netsniff-ng.git
 *    cd netsniff-ng/src/bpfc/
 *    make && make install
 *    vim firstfilter
 *      ldh #proto
 *      jeq #0x800,L1,L2
 *      L1: ret #0xffffff
 *      L2: ret #0
 *    And finally cat the code into the fb's procfs file, e.g.
 *    bpfc firstfilter > /proc/net/lana/fblock/fb1
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/prefetch.h>
#include <linux/filter.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/uaccess.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct fb_bpf_priv {
	idp_t port[2];
	struct sk_filter *filter;
	spinlock_t flock;
} ____cacheline_aligned_in_smp;

struct sock_fprog_kern {
	unsigned short len;
	struct sock_filter *filter;
};

static int __fb_bpf_init_filter(struct fb_bpf_priv *fb_priv,
				struct sock_fprog_kern *fprog)
{
	int err;
	struct sk_filter *sf, *sfold;
	unsigned int fsize;
	unsigned long flags;

	if (fprog->filter == NULL)
		return -EINVAL;
	fsize = sizeof(struct sock_filter) * fprog->len;
	sf = kmalloc(fsize + sizeof(*sf), GFP_KERNEL);
	if (!sf)
		return -ENOMEM;
	memcpy(sf->insns, fprog->filter, fsize);
	atomic_set(&sf->refcnt, 1);
	sf->len = fprog->len;
	sf->bpf_func = sk_run_filter;
	err = sk_chk_filter(sf->insns, sf->len);
	if (err) {
		kfree(sf);
		return err;
	}
	spin_lock_irqsave(&fb_priv->flock, flags);
	sfold = fb_priv->filter;
	fb_priv->filter = sf;
	spin_unlock_irqrestore(&fb_priv->flock, flags);
	if (sfold)
		kfree(sfold);
	return 0;
}

static int fb_bpf_init_filter(struct fblock *fb, struct sock_fprog_kern *fprog)
{
	int err;
	struct fb_bpf_priv __percpu *fb_priv;
	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();
	err = __fb_bpf_init_filter(fb_priv, fprog);
	if (err != 0)
		printk(KERN_ERR "[%s::%s] fb_bpf_init_filter error: %d\n",
		       fb->name, fb->factory->type, err);
	return err;
}

static void __fb_bpf_cleanup_filter(struct fb_bpf_priv *fb_priv)
{
	unsigned long flags;
	struct sk_filter *sfold;

	spin_lock_irqsave(&fb_priv->flock, flags);
	sfold = fb_priv->filter;
	fb_priv->filter = NULL;
	spin_unlock_irqrestore(&fb_priv->flock, flags);
	if (sfold)
		kfree(sfold);
}

static void fb_bpf_cleanup_filter(struct fblock *fb)
{
	struct fb_bpf_priv *fb_priv;
	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();
	__fb_bpf_cleanup_filter(fb_priv);
}

static int fb_bpf_netrx(const struct fblock * const fb,
			struct sk_buff * const skb,
			enum path_type * const dir)
{
	int drop = 0;
	unsigned int pkt_len;
	unsigned long flags;
	struct fb_bpf_priv *fb_priv;
	fb_priv = rcu_dereference_raw(fb->private_data);
	spin_lock_irqsave(&fb_priv->flock, flags);
	if (fb_priv->filter) {
		pkt_len = SK_RUN_FILTER(fb_priv->filter, skb);
		if (pkt_len < skb->len) {
			spin_unlock_irqrestore(&fb_priv->flock, flags);
			kfree_skb(skb);
			return PPE_DROPPED;
		}
	}
	write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
	if (fb_priv->port[*dir] == IDP_UNKNOWN)
		drop = 1;
	spin_unlock_irqrestore(&fb_priv->flock, flags);
	if (drop) {
		kfree_skb(skb);
		return PPE_DROPPED;
	}
	return PPE_SUCCESS;
}

static int fb_bpf_event(struct notifier_block *self, unsigned long cmd,
			void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_bpf_priv *fb_priv;

	rcu_read_lock();
	fb = rcu_dereference_raw(container_of(self, struct fblock_notifier, nb)->self);
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	switch (cmd) {
	case FBLOCK_BIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == IDP_UNKNOWN) {
			spin_lock(&fb_priv->flock);
			fb_priv->port[msg->dir] = msg->idp;
			spin_unlock(&fb_priv->flock);
		} else {
			ret = NOTIFY_BAD;
		}
		break; }
	case FBLOCK_UNBIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == msg->idp) {
			spin_lock(&fb_priv->flock);
			fb_priv->port[msg->dir] = IDP_UNKNOWN;
			spin_unlock(&fb_priv->flock);
		} else {
			ret = NOTIFY_BAD;
		}
		break; }
	default:
		break;
	}

	return ret;
}

static int fb_bpf_proc_show_filter(struct seq_file *m, void *v)
{
	unsigned long flags;
	struct fblock *fb = (struct fblock *) m->private;
	struct fb_bpf_priv *fb_priv;
	struct sk_filter *sf;

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();
	spin_lock_irqsave(&fb_priv->flock, flags);
	sf = fb_priv->filter;
	if (sf) {
		unsigned int i;
		if (sf->bpf_func == sk_run_filter)
			seq_puts(m, "bpf jit: 0\n");
		else
			seq_puts(m, "bpf jit: 1\n");
		seq_puts(m, "code:\n");
		for (i = 0; i < sf->len; ++i) {
			char sline[32];
			memset(sline, 0, sizeof(sline));
			snprintf(sline, sizeof(sline),
				 "{ 0x%x, %u, %u, 0x%x }\n",
				 sf->insns[i].code,
				 sf->insns[i].jt,
				 sf->insns[i].jf,
				 sf->insns[i].k);
			sline[sizeof(sline) - 1] = 0;
			seq_puts(m, sline);
		}
	}
	spin_unlock_irqrestore(&fb_priv->flock, flags);
	return 0;
}

static int fb_bpf_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, fb_bpf_proc_show_filter, PDE(inode)->data);
}

#define MAX_BUFF_SIZ	16384
#define MAX_INSTR_SIZ	512

static ssize_t fb_bpf_proc_write(struct file *file, const char __user * ubuff,
				 size_t count, loff_t * offset)
{
	int i;
	ssize_t ret = 0;
	char *code, *ptr1, *ptr2;
	size_t len = MAX_BUFF_SIZ;
	struct sock_fprog_kern *fp;
	struct fblock *fb = PDE(file->f_path.dentry->d_inode)->data;

	if (count > MAX_BUFF_SIZ)
		return -EINVAL;
	if (count < MAX_BUFF_SIZ)
		len = count;
	code = kmalloc(len, GFP_KERNEL);
	if (!code)
		return -ENOMEM;
	fp = kmalloc(sizeof(*fp), GFP_KERNEL);
	if (!fp)
		goto err;
	fp->filter = kmalloc(MAX_INSTR_SIZ * sizeof(struct sock_filter), GFP_KERNEL);
	if (!fp->filter)
		goto err2;
	memset(code, 0, len);
	if (copy_from_user(code, ubuff, len)) {
		ret = -EFAULT;
		goto err3;
	}
	ptr1 = code;
	ptr2 = NULL;
	fp->len = 0;
	while (fp->len < MAX_INSTR_SIZ && (char *) (code + len) > ptr1) {
		while (ptr1 && (*ptr1 == ' ' || *ptr1 == '{'))
			ptr1++;
		fp->filter[fp->len].code = (__u16) simple_strtoul(ptr1, &ptr2, 16);
		while (ptr2 && (*ptr2 == ' ' || *ptr2 == ','))
			ptr2++;
		fp->filter[fp->len].jt = (__u8) simple_strtoul(ptr2, &ptr1, 10);
		while (ptr1 && (*ptr1 == ' ' || *ptr1 == ','))
			ptr1++;
		fp->filter[fp->len].jf = (__u8) simple_strtoul(ptr1, &ptr2, 10);
		while (ptr2 && (*ptr2 == ' ' || *ptr2 == ','))
			ptr2++;
		fp->filter[fp->len].k = (__u32) simple_strtoul(ptr2, &ptr1, 16);
		while (ptr1 && (*ptr1 == ' ' || *ptr1 == ',' || *ptr1 == '}' ||
				*ptr1 == '\n'))
			ptr1++;
		fp->len++;
	}
	if (fp->len == MAX_INSTR_SIZ) {
		printk(KERN_ERR "[%s::%s] Maximun instruction size exeeded!\n",
		       fb->name, fb->factory->type);
		goto err3;
	}
	printk(KERN_ERR "[%s::%s] Parsed code:\n", fb->name, fb->factory->type);
	for (i = 0; i < fp->len; ++i) {
		printk(KERN_INFO "[%s::%s] %d: c:0x%x jt:%u jf:%u k:0x%x\n",
		       fb->name, fb->factory->type, i,
		       fp->filter[i].code, fp->filter[i].jt, fp->filter[i].jf,
		       fp->filter[i].k);
	}
	fb_bpf_cleanup_filter(fb);
	ret = fb_bpf_init_filter(fb, fp);
	if (!ret)
		printk(KERN_INFO "[%s::%s] Filter injected!\n",
		       fb->name, fb->factory->type);
	else {
		printk(KERN_ERR "[%s::%s] Filter injection error: %ld!\n",
		       fb->name, fb->factory->type, ret);
		fb_bpf_cleanup_filter(fb);
	}
	kfree(code);
	kfree(fp->filter);
	kfree(fp);
	return count;
err3:
	kfree(fp->filter);
err2:
	kfree(fp);
err:
	kfree(code);
	return !ret ? -ENOMEM : ret;
}

static const struct file_operations fb_bpf_proc_fops = {
	.owner   = THIS_MODULE,
	.open    = fb_bpf_proc_open,
	.read    = seq_read,
	.llseek  = seq_lseek,
	.write   = fb_bpf_proc_write,
	.release = single_release,
};

static struct fblock *fb_bpf_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_bpf_priv *fb_priv;
	struct proc_dir_entry *fb_proc;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	spin_lock_init(&fb_priv->flock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->filter = NULL;
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_bpf_netrx;
	fb->event_rx = fb_bpf_event;
	fb_proc = proc_create_data(fb->name, 0444, fblock_proc_dir,
				   &fb_bpf_proc_fops, (void *)(long) fb);
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
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	return NULL;
}

static void fb_bpf_dtor(struct fblock *fb)
{
	free_percpu(rcu_dereference_raw(fb->private_data));
	remove_proc_entry(fb->name, fblock_proc_dir);
	module_put(THIS_MODULE);
}

static void fb_bpf_dtor_outside_rcu(struct fblock *fb)
{
	fb_bpf_cleanup_filter(fb);
}

static struct fblock_factory fb_bpf_factory = {
	.type = "ch.ethz.csg.bpf",
	.mode = MODE_DUAL,
	.ctor = fb_bpf_ctor,
	.dtor = fb_bpf_dtor,
	.dtor_outside_rcu = fb_bpf_dtor_outside_rcu,
	.owner = THIS_MODULE,
};

static int __init init_fb_bpf_module(void)
{
	return register_fblock_type(&fb_bpf_factory);
}

static void __exit cleanup_fb_bpf_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_bpf_factory);
}

module_init(init_fb_bpf_module);
module_exit(cleanup_fb_bpf_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA Berkeley Packet Filter module");
