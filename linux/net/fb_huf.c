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

struct fb_huf_priv {
	idp_t port[2];
	seqlock_t lock;
	rwlock_t klock;
} ____cacheline_aligned_in_smp;


/* Node of the huffman tree */
struct huf_node{
    int value;
    char letter;
    struct huf_node *left,*right;
};

typedef struct huf_node Node;

/* 81 = 8.1%, 128 = 12.8% and so on. The 27th frequency is the space. Source is Wikipedia */
int englishLetterFrequencies [27] = {81, 15, 28, 43, 128, 23, 20, 61, 71, 2, 1, 40, 24, 69, 76, 20, 1, 61, 64, 91, 28, 10, 24, 1, 20, 1, 130};

int codeTable[27], codeTable2[27];

int len(int code){
	if (code < 10)
		return 1;
	else if (code >=10 && code < 100)
		return 2;
	else if (code >= 100 && code < 1000)
		return 3;
	else if (code >= 1000 && code < 10000)
		return 4;
	else if (code >= 10000 && code < 100000)
		return 5;
	else if (code >= 100000 && code < 1000000)
		return 6;
	else if (code >= 1000000 && code < 10000000)
		return 7;
	else if (code >= 10000000 && code < 100000000)
		return 8;
	else if (code >= 100000000 && code < 1000000000)
		return 9;
	else{
		printk(KERN_ERR "code longer than 9 bits - not yet implemented\n");
		return 10;
	}
}

/*finds and returns the small sub-tree in the forrest*/
int findSmaller (Node *array[], int differentFrom){
    int smaller;
    int i = 0;

    while (array[i]->value==-1)
        i++;
    smaller=i;
    if (i==differentFrom){
        i++;
        while (array[i]->value==-1)
            i++;
        smaller=i;
    }

    for (i=1;i<27;i++){
        if (array[i]->value==-1)
            continue;
        if (i==differentFrom)
            continue;
        if (array[i]->value<array[smaller]->value)
            smaller = i;
    }

    return smaller;
}

/*builds the huffman tree and returns its address by reference*/
void buildHuffmanTree(Node **tree){
    Node *temp;
    Node *array[27];
    int i, subTrees = 27;
    int smallOne,smallTwo;

    for (i=0;i<27;i++){
        array[i] = kmalloc(sizeof(Node), GFP_KERNEL);
        array[i]->value = englishLetterFrequencies[i];
        array[i]->letter = i;
        array[i]->left = NULL;
        array[i]->right = NULL;
    }

    while (subTrees>1){
        smallOne=findSmaller(array,-1);
        smallTwo=findSmaller(array,smallOne);
        temp = array[smallOne];
        array[smallOne] = kmalloc(sizeof(Node), GFP_KERNEL);
        array[smallOne]->value=temp->value+array[smallTwo]->value;
        array[smallOne]->letter=127;
        array[smallOne]->left=array[smallTwo];
        array[smallOne]->right=temp;
        array[smallTwo]->value=-1;
        subTrees--;
    }

    *tree = array[smallOne];

return;
}

/* builds the table with the bits for each letter. 1 stands for binary 0 and 2 for binary 1 (used to facilitate arithmetic)*/
void fillTable(Node *tree, int Code){
    if (tree->letter<27)
        codeTable[(int)tree->letter] = Code;
    else{
        fillTable(tree->left, Code*10+1);
        fillTable(tree->right, Code*10+2);
    }

    return;
}

void invertCodes(void){
    int i, n, copy;

    for (i=0;i<27;i++){
        n = codeTable[i];
        copy = 0;
        while (n>0){
            copy = copy * 10 + n %10;
            n /= 10;
        }
        codeTable2[i]=copy;
    }

return;
}


static void compress(struct sk_buff * const skb){
	char tmp_buf[1500];
	int skb_len = 0;
	char bit, c, x = 0;
    	int n,length,bitsLeft = 8;
    	int originalBits = 0, compressedBits = 0;
	int i = 0;
	int j = 0;
	memcpy(tmp_buf, skb->data, skb->len);
	skb_len = skb->len;

	for(i = 0; i < skb_len; i++){
		c = tmp_buf[i];
        	originalBits++;
        	if (c==32){
        		length = len(codeTable2[26]);
            		n = codeTable2[26];
        	}
		else if (c >= 65 && c <= 90) {
			length=len(codeTable2[c-65]);
            		n = codeTable2[c-65];
			printk(KERN_ERR "upper case is converted to lower case\n");
			
		}
        	else if (c <= 97 && c <= 122) {
            		length=len(codeTable2[c-97]);
            		n = codeTable2[c-97];
        	}
		else
			continue;

        	while (length>0){
            		compressedBits++;
            		bit = n % 10 - 1;
            		n /= 10;
            		x = x | bit;
            		bitsLeft--;
            		length--;
            		if (bitsLeft==0){
               			// fputc(x,output);
				skb->data[j] = x;
                		x = 0;
                		bitsLeft = 8;
				j++;
            		}
            		x = x << 1;
        	}
    	}

    	if (bitsLeft!=8){
        	x = x << (bitsLeft-1);
        	//fputc(x,output);
		skb->data[j] = x;
		j++;
    	}

	skb_trim(skb, j);

    /*print details of compression on the screen*/
    printk(KERN_INFO "Original bits = %d, %d\n",originalBits*8, skb_len);
    printk(KERN_INFO "Compressed bits = %d, %d\n",compressedBits, j);
   
    return;
}


/*function to decompress the input -- unused, just to have it...*/
void decompressFile (FILE *input, FILE *output, Node *tree){
    Node *current = tree;
    char c,bit;
    char mask = 1 << 7;
    int i;

    while ((c=fgetc(input))!=EOF){

        for (i=0;i<8;i++){
            bit = c & mask;
            c = c << 1;
            if (bit==0){
                current = current->left;
                if (current->letter!=127){
                    if (current->letter==26)
                        fputc(32, output);
                    else
                        fputc(current->letter+97,output);
                    current = tree;
                }
            }

            else{
                current = current->right;
                if (current->letter!=127){
                    if (current->letter==26)
                        fputc(32, output);
                    else
                        fputc(current->letter+97,output);
                    current = tree;
                }
            }
        }
    }

    return;
}



static int fb_huf_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	unsigned int seq;
//	unsigned int padding;
	struct fb_huf_priv *fb_priv;
//	size_t i = 0;
//	unsigned char ciphertext[16];

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			goto drop;
	} while (read_seqretry(&fb_priv->lock, seq));

	read_lock(&fb_priv->klock);

	//send it trough compression
	compress(skb);	

	read_unlock(&fb_priv->klock);

	return PPE_SUCCESS;
drop:
	printk(KERN_INFO "[fb_aes] drop packet. Out of key material?\n");
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_huf_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_huf_priv *fb_priv;

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

static int fb_huf_proc_show(struct seq_file *m, void *v)
{
	struct fblock *fb = (struct fblock *) m->private;
	struct fb_huf_priv *fb_priv;
	char sline[64];

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	memset(sline, 0, sizeof(sline));

	read_lock(&fb_priv->klock);
	snprintf(sline, sizeof(sline), "hello from huf");
	read_unlock(&fb_priv->klock);

	seq_puts(m, sline);
	return 0;
}

static int fb_huf_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, fb_huf_proc_show, PDE(inode)->data);
}

static ssize_t fb_huf_proc_write(struct file *file, const char __user * ubuff,
				 size_t count, loff_t * offset)
{
	struct fblock *fb = PDE(file->f_path.dentry->d_inode)->data;
	struct fb_huf_priv *fb_priv;

	printk(KERN_INFO "huf does not support proc write\n");
	return count;
}

static const struct file_operations fb_huf_proc_fops = {
	.owner   = THIS_MODULE,
	.open    = fb_huf_proc_open,
	.read    = seq_read,
	.llseek  = seq_lseek,
	.write   = fb_huf_proc_write,
	.release = single_release,
};

static struct fblock *fb_huf_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_huf_priv *fb_priv;
	struct proc_dir_entry *fb_proc;
	Node *tree;
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

	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;

	fb->netfb_rx = fb_huf_netrx;
	fb->event_rx = fb_huf_event;
//	fb->linearize = fb_aes_linearize;
//	fb->delinearize = fb_aes_delinearize;
	fb_proc = proc_create_data(fb->name, 0444, fblock_proc_dir,
				   &fb_huf_proc_fops, (void *)(long) fb);
	if (!fb_proc)
		goto err3;

	ret = register_fblock_namespace(fb);
	if (ret)
		goto err4;

	__module_get(THIS_MODULE);

	
	buildHuffmanTree(&tree);
	fillTable(tree, 0);
	invertCodes();


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

static void fb_huf_dtor_outside_rcu(struct fblock *fb)
{
//	kfree(((struct fb_aes_priv *)rcu_dereference_raw(fb->private_data))->key);
}

static void fb_huf_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	remove_proc_entry(fb->name, fblock_proc_dir);
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_huf_factory = {
	.type = "ch.ethz.csg.huf",
	.mode = MODE_DUAL,
	.ctor = fb_huf_ctor,
	.dtor = fb_huf_dtor,
	.dtor_outside_rcu = fb_huf_dtor_outside_rcu,
	.owner = THIS_MODULE,
	.properties = { [0] = "privacy" },
};

static int __init init_fb_huf_module(void)
{
	return register_fblock_type(&fb_huf_factory);
}

static void __exit cleanup_fb_huf_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_huf_factory);
}

module_init(init_fb_huf_module);
module_exit(cleanup_fb_huf_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ariane Keller <ariane.keller@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA Huffman module. Implementation from programminglogic.com/implementing-huffman-coding-in-c");
