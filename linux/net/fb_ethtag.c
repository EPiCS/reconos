/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/notifier.h>
#include <linux/netdevice.h>
#include <linux/rtnetlink.h>
#include <linux/ethtool.h>
#include <linux/etherdevice.h>
#include <linux/if_ether.h>
#include <linux/if_arp.h>
#include <linux/if.h>
#include <linux/list.h>
#include <linux/u64_stats_sync.h>
#include <linux/seqlock.h>
#include <net/rtnetlink.h>

#include "xt_fblock.h"
#include "xt_engine.h"

#define IFF_VLINK_MAS	0x20000 /* Master device */
#define IFF_VLINK_DEV	0x40000 /* Slave device */
#define IFF_IS_BRIDGED  0x60000

/* Ethernet LANA packet with 10 Bit tag ID */
#define ETH_P_LANA    0xAC00

struct pcpu_dstats {
	u64 rx_packets;
	u64 rx_bytes;
	u64 rx_multicast;
	u64 tx_packets;
	u64 tx_bytes;
	struct u64_stats_sync syncp;
	u32 rx_errors;
	u32 tx_dropped;
};

static struct net_device_ops fb_ethtag_netdev_ops __read_mostly;
static struct rtnl_link_ops fb_ethtag_rtnl_ops __read_mostly;
static struct ethtool_ops fb_ethtag_ethtool_ops __read_mostly;
static struct header_ops fb_ethtag_header_ops __read_mostly;

static LIST_HEAD(fb_ethtag_vdevs);
static DEFINE_SPINLOCK(fb_ethtag_vdevs_lock);

struct fb_ethtag_private;

struct fb_ethtag_private_inner {
	idp_t port[2];
	seqlock_t lock;
	struct fb_ethtag_private *vdev;
} ____cacheline_aligned_in_smp;

struct fb_ethtag_private {
	u16 tag;
	struct list_head list;
	struct net_device *self;
	struct net_device *real_dev;
	int (*netvif_rx)(struct sk_buff *skb, struct fb_ethtag_private *vdev);
	struct fblock *fb;
};

static int fb_ethtag_init(struct net_device *dev)
{
	dev->dstats = alloc_percpu(struct pcpu_dstats);
	if (!dev->dstats)
		return -ENOMEM;
	return 0;
}

static void fb_ethtag_uninit(struct net_device *dev)
{
	free_percpu(dev->dstats);
}

static int fb_ethtag_open(struct net_device *dev)
{
	struct fb_ethtag_private *dev_priv = netdev_priv(dev);
	netif_start_queue(dev);
	if (netif_carrier_ok(dev_priv->real_dev)) {
		netif_tx_lock_bh(dev);
		netif_carrier_on(dev);
		netif_tx_unlock_bh(dev);
	}
	return 0;
}

static int fb_ethtag_stop(struct net_device *dev)
{
	netif_tx_lock_bh(dev);
	netif_carrier_off(dev);
	netif_tx_unlock_bh(dev);
	netif_stop_queue(dev);
	return 0;
}

static inline int fb_eth_dev_is_bridged(struct net_device *dev)
{
	return (dev->priv_flags & IFF_IS_BRIDGED) == IFF_IS_BRIDGED;
}

static inline int fb_ethtag_real_dev_is_hooked(struct net_device *dev)
{
	return (dev->priv_flags & IFF_VLINK_MAS) == IFF_VLINK_MAS;
}

static inline void fb_ethtag_make_real_dev_hooked(struct net_device *dev)
{
	dev->priv_flags |= IFF_VLINK_MAS;
}

static inline void fb_ethtag_make_real_dev_unhooked(struct net_device *dev)
{
	dev->priv_flags &= ~IFF_VLINK_MAS;
}

static int fb_ethtag_event(struct notifier_block *self, unsigned long cmd,
			   void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_ethtag_private_inner *fb_priv;

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

static int fb_ethtag_queue_xmit(struct sk_buff *skb,
				struct net_device *dev)
{
	struct fb_ethtag_private *dev_priv = netdev_priv(dev);
	skb_set_dev(skb, dev_priv->real_dev);
	return dev_queue_xmit(skb);
}

netdev_tx_t fb_ethtag_start_xmit(struct sk_buff *skb,
				 struct net_device *dev)
{
	int ret;
	struct pcpu_dstats *dstats;
	dstats = this_cpu_ptr(dev->dstats);
	ret = fb_ethtag_queue_xmit(skb, dev);
	if (likely(ret == NET_XMIT_SUCCESS || ret == NET_XMIT_CN)) {
		u64_stats_update_begin(&dstats->syncp);
		dstats->tx_packets++;
		dstats->tx_bytes += skb->len;
		u64_stats_update_end(&dstats->syncp);
	} else 
		this_cpu_inc(dstats->tx_dropped);
	return ret;
}

static int fb_ethtag_netrx(const struct fblock * const fb,
			   struct sk_buff * const skb,
			   enum path_type * const dir)
{
	struct fb_ethtag_private_inner *fb_priv;
	fb_priv = rcu_dereference(fb->private_data);
	skb->dev = fb_priv->vdev->self;
	write_next_idp_to_skb(skb, fb->idp, IDP_UNKNOWN);
	dev_queue_xmit(skb);
	return PPE_DROPPED;
}

int fb_ethtag_handle_frame_virt(struct sk_buff *skb,
				struct fb_ethtag_private *vdev)
{
	unsigned int seq;
	struct fb_ethtag_private_inner *fb_priv;
	skb_orphan(skb);
	fb_priv = rcu_dereference(vdev->fb->private_data);
	if (fb_priv->port[TYPE_INGRESS] == IDP_UNKNOWN)
		goto drop;
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, vdev->fb->idp,
				      fb_priv->port[TYPE_INGRESS]);
	} while (read_seqretry(&fb_priv->lock, seq));
        process_packet(skb, TYPE_INGRESS);
	return NET_RX_SUCCESS;
drop:
	kfree_skb(skb);
	return NET_RX_SUCCESS;
}

static rx_handler_result_t fb_ethtag_handle_frame(struct sk_buff **pskb)
{
	int ret, bypass_drop = 0;
	u16 vtag;
	struct sk_buff *skb = *pskb;
	struct net_device *dev;
	struct fb_ethtag_private *vdev;
	struct pcpu_dstats *dstats;

	dev = skb->dev;
	if (unlikely((dev->flags & IFF_UP) != IFF_UP))
		goto drop;
	if (unlikely(skb->pkt_type == PACKET_LOOPBACK))
		return RX_HANDLER_PASS;
	if (unlikely(!is_valid_ether_addr(eth_hdr(skb)->h_source)))
		goto drop;
	skb = skb_share_check(skb, GFP_ATOMIC);
	if (unlikely(!skb))
		return RX_HANDLER_CONSUMED;
	if ((eth_hdr(skb)->h_proto & __constant_htons(ETH_P_LANA)) !=
	    __constant_htons(ETH_P_LANA))
		return RX_HANDLER_PASS;
	vtag = ntohs(eth_hdr(skb)->h_proto &
		      ~__constant_htons(ETH_P_LANA));
	list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list) {
		if (vtag == vdev->tag && dev == vdev->real_dev) {
			dstats = this_cpu_ptr(vdev->self->dstats);
			ret = vdev->netvif_rx(skb, vdev);
			bypass_drop = 1;
			if (ret == NET_RX_SUCCESS) {
				u64_stats_update_begin(&dstats->syncp);
				dstats->rx_packets++;
				dstats->rx_bytes += skb->len;
				u64_stats_update_end(&dstats->syncp);
			} else
				this_cpu_inc(dstats->rx_errors);
			break;
		}
	}
drop:
	if (!bypass_drop)
		kfree_skb(skb);
	return RX_HANDLER_CONSUMED;
}

static void fb_ethtag_ethtool_get_drvinfo(struct net_device *dev,
					    struct ethtool_drvinfo *drvinfo)
{
	snprintf(drvinfo->driver, sizeof(drvinfo->driver), "ethtag");
	snprintf(drvinfo->version, sizeof(drvinfo->version), "0.1");
}

static u32 fb_ethtag_ethtool_get_rx_csum(struct net_device *dev)
{
	const struct fb_ethtag_private *vdev = netdev_priv(dev);
	return dev_ethtool_get_rx_csum(vdev->real_dev);
}

static int fb_ethtag_ethtool_get_settings(struct net_device *dev,
					  struct ethtool_cmd *cmd)
{
	const struct fb_ethtag_private *vdev = netdev_priv(dev);
	return __ethtool_get_settings(vdev->real_dev, cmd);
}

static u32 fb_ethtag_ethtool_get_flags(struct net_device *dev)
{
	const struct fb_ethtag_private *vdev = netdev_priv(dev);
	return dev_ethtool_get_flags(vdev->real_dev);
}

static void fb_ethtag_dev_setup(struct net_device *dev)
{
	ether_setup(dev);
	dev->ethtool_ops = &fb_ethtag_ethtool_ops;
	dev->netdev_ops = &fb_ethtag_netdev_ops;
	dev->rtnl_link_ops = &fb_ethtag_rtnl_ops;
	dev->header_ops = &fb_ethtag_header_ops;
	dev->tx_queue_len = 0;
	dev->priv_flags	&= ~IFF_XMIT_DST_RELEASE;
	dev->destructor = free_netdev;
	random_ether_addr(dev->dev_addr);
	memset(dev->broadcast, 0, sizeof(dev->broadcast));
}

static int fb_ethtag_validate(struct nlattr **tb, struct nlattr **data)
{
	if (tb[IFLA_ADDRESS]) {
		if (nla_len(tb[IFLA_ADDRESS]) != ETH_ALEN)
			return -EINVAL;
		if (!is_valid_ether_addr(nla_data(tb[IFLA_ADDRESS])))
			return -EADDRNOTAVAIL;
	}
	return 0;
}

static int fb_ethtag_create_header(struct sk_buff *skb,
				     struct net_device *dev,
				     unsigned short type, const void *daddr,
				     const void *saddr, unsigned len)
{
	const struct fb_ethtag_private *vdev = netdev_priv(dev);
	return dev_hard_header(skb, vdev->real_dev, type, daddr,
			       saddr ? : dev->dev_addr, len);
}

static struct rtnl_link_stats64 *
fb_ethtag_get_stats64(struct net_device *dev,
			struct rtnl_link_stats64 *stats)
{
	int i;
	for_each_possible_cpu(i) {
		u64 tbytes, tpackets, rbytes, rpackets;
		unsigned int start;
		const struct pcpu_dstats *dstats;
		dstats = per_cpu_ptr(dev->dstats, i);
		do {
			start = u64_stats_fetch_begin(&dstats->syncp);
			tbytes = dstats->tx_bytes;
			tpackets = dstats->tx_packets;
			rbytes = dstats->rx_bytes;
			rpackets = dstats->rx_packets;
		} while (u64_stats_fetch_retry(&dstats->syncp, start));
		stats->tx_bytes += tbytes;
		stats->tx_packets += tpackets;
		stats->rx_bytes += rbytes;
		stats->rx_packets += rpackets;
	}
	return stats;
}

static void fb_ethtag_destroy_fblock(struct fblock *fb)
{
	unregister_fblock_namespace_no_rcu(fb);
	cleanup_fblock(fb);
	kfree(rcu_dereference_raw(fb->private_data));
	kfree_fblock(fb);
	module_put(THIS_MODULE);
}

static struct fblock *fb_ethtag_build_fblock(struct fb_ethtag_private *vdev)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_ethtag_private_inner *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->vdev = vdev;
	ret = init_fblock(fb, vdev->self->name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_ethtag_netrx;
	fb->event_rx = fb_ethtag_event;
	fb->factory = NULL;
	ret = register_fblock_namespace(fb);
	if (ret)
		goto err3;
	__module_get(THIS_MODULE);
	smp_wmb();
	return fb;
err3:
	cleanup_fblock_ctor(fb);
err2:
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	fb = NULL;
	return NULL;
}

static int fb_ethtag_add_dev(struct vlinknlmsg *vhdr,
			     struct nlmsghdr *nlh)
{
	int ret;
	unsigned long flags;
	struct net_device *dev;
	struct net_device *root;
	struct fb_ethtag_private *dev_priv, *vdev;

	if (vhdr->cmd != VLINKNLCMD_ADD_DEVICE)
		return NETLINK_VLINK_RX_NXT;
	root = dev_get_by_name(&init_net, vhdr->virt_name);
	if (root)
		goto err_put;
	root = dev_get_by_name(&init_net, vhdr->real_name);
	if (root && (root->priv_flags & IFF_VLINK_DEV) == IFF_VLINK_DEV)
		goto err_put;
	else if (!root)
		goto err;
	vhdr->port &= 0x3FF;
	rcu_read_lock();
	list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list) {
		if (vdev->tag == vhdr->port) {
			rcu_read_unlock();
			goto err_put;
		}
	}
	rcu_read_unlock();
	dev = alloc_netdev(sizeof(*dev_priv), vhdr->virt_name,
			   fb_ethtag_dev_setup);
	if (!dev)
		goto err_put;
	ret = dev_alloc_name(dev, dev->name);
	if (ret)
		goto err_free;
	ret = register_netdev(dev);
	if (ret)
		goto err_free;
	dev_priv = netdev_priv(dev);
	dev->priv_flags |= vhdr->flags;
	dev->priv_flags |= IFF_VLINK_DEV;
	dev_priv->tag = vhdr->port;
	dev_priv->self = dev;
	dev_priv->real_dev = root;
	dev_priv->netvif_rx = fb_ethtag_handle_frame_virt;
	dev_priv->fb = fb_ethtag_build_fblock(dev_priv);
	if (!dev_priv->fb)
		goto err_unreg;
	netif_stacked_transfer_operstate(dev_priv->real_dev, dev);
	dev_put(dev_priv->real_dev);
	spin_lock_irqsave(&fb_ethtag_vdevs_lock, flags);
	list_add_rcu(&dev_priv->list, &fb_ethtag_vdevs);
	spin_unlock_irqrestore(&fb_ethtag_vdevs_lock, flags);
	netif_tx_lock_bh(dev);
	netif_carrier_off(dev);
	netif_tx_unlock_bh(dev);
	printk(KERN_INFO "[lana] %s stacked on carrier %s:%u\n",
	       vhdr->virt_name, vhdr->real_name, dev_priv->tag);
	return NETLINK_VLINK_RX_STOP;
err_unreg:
	unregister_netdevice(dev);
err_free:
	dev_put(root);
	free_netdev(dev);
err:
	return NETLINK_VLINK_RX_EMERG;
err_put:
	dev_put(root);
	goto err;
}

static int fb_ethtag_start_hook_dev(struct vlinknlmsg *vhdr,
				    struct nlmsghdr *nlh)
{
	int ret;
	struct net_device *root;

	if (vhdr->cmd != VLINKNLCMD_START_HOOK_DEVICE)
		return NETLINK_VLINK_RX_NXT;
	root = dev_get_by_name(&init_net, vhdr->real_name);
	if (root && (root->priv_flags & IFF_VLINK_DEV) == IFF_VLINK_DEV)
		goto err;
	else if (!root)
		return NETLINK_VLINK_RX_EMERG;
	if (fb_eth_dev_is_bridged(root))
		goto out;
	if (fb_ethtag_real_dev_is_hooked(root))
		goto out;
	rtnl_lock();
	ret = netdev_rx_handler_register(root, fb_ethtag_handle_frame,
					 NULL);
	rtnl_unlock();
	if (ret)
		goto err;
	fb_ethtag_make_real_dev_hooked(root);
	printk(KERN_INFO "[lana] hook attached to carrier %s\n",
	       vhdr->real_name);
out:
	dev_put(root);
	return NETLINK_VLINK_RX_STOP;
err:
	dev_put(root);
	return NETLINK_VLINK_RX_EMERG;
}

static int fb_ethtag_stop_hook_dev(struct vlinknlmsg *vhdr,
				   struct nlmsghdr *nlh)
{
	struct net_device *root;

	if (vhdr->cmd != VLINKNLCMD_STOP_HOOK_DEVICE)
		return NETLINK_VLINK_RX_NXT;
	root = dev_get_by_name(&init_net, vhdr->real_name);
	if (root && (root->priv_flags & IFF_VLINK_DEV) == IFF_VLINK_DEV)
		goto err;
	else if (!root)
		return NETLINK_VLINK_RX_EMERG;
	if (!fb_ethtag_real_dev_is_hooked(root))
		goto out;
	rtnl_lock();
	netdev_rx_handler_unregister(root);
	rtnl_unlock();
	fb_ethtag_make_real_dev_unhooked(root);
	printk(KERN_INFO "[lana] hook detached from carrier %s\n",
	       vhdr->real_name);
out:
	dev_put(root);
	return NETLINK_VLINK_RX_STOP;
err:
	dev_put(root);
	return NETLINK_VLINK_RX_EMERG;
}

static void fb_ethtag_rm_dev_common(struct net_device *dev)
{
	netif_tx_lock_bh(dev);
	netif_carrier_off(dev);
	netif_tx_unlock_bh(dev);
	printk(KERN_INFO "[lana] %s unregistered\n", dev->name);
	rtnl_lock();
	unregister_netdevice(dev);
	rtnl_unlock();
}

static int fb_ethtag_rm_dev(struct vlinknlmsg *vhdr, struct nlmsghdr *nlh)
{
	int count;
	unsigned long flags;
	struct fb_ethtag_private *dev_priv, *vdev;
	struct net_device *dev;

	if (vhdr->cmd != VLINKNLCMD_RM_DEVICE)
		return NETLINK_VLINK_RX_NXT;
	dev = dev_get_by_name(&init_net, vhdr->virt_name);
	if (!dev)
		return NETLINK_VLINK_RX_EMERG;
	if ((dev->priv_flags & IFF_VLINK_DEV) != IFF_VLINK_DEV)
		goto err_put;
	if ((dev->flags & IFF_RUNNING) == IFF_RUNNING)
		goto err_put;
	dev_priv = netdev_priv(dev);
	if (atomic_read(&dev_priv->fb->refcnt) > 2) {
		printk(KERN_INFO "Cannot remove vlink dev! Still in use by "
		       "others!\n");
		goto err_put;
	}
	dev_put(dev);
	count = 0;
	rcu_read_lock();
	list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list)
		if (dev_priv->real_dev == vdev->real_dev)
			count++;
	rcu_read_unlock();
	if (count == 1) {
		/* We're last client on carrier! */
		if (fb_ethtag_real_dev_is_hooked(dev_priv->real_dev)) {
			rtnl_lock();
			netdev_rx_handler_unregister(dev_priv->real_dev);
			rtnl_unlock();
			fb_ethtag_make_real_dev_unhooked(dev_priv->real_dev);
			printk(KERN_INFO "[lana] hook detached from %s\n",
			       dev_priv->real_dev->name);
		}
	}
	spin_lock_irqsave(&fb_ethtag_vdevs_lock, flags);
	list_del_rcu(&dev_priv->list);
	spin_unlock_irqrestore(&fb_ethtag_vdevs_lock, flags);
	fb_ethtag_destroy_fblock(dev_priv->fb);
	fb_ethtag_rm_dev_common(dev);
	return NETLINK_VLINK_RX_STOP;
err_put:
	dev_put(dev);
	return NETLINK_VLINK_RX_EMERG;
}

static int fb_ethtag_dev_event(struct notifier_block *self,
				 unsigned long event, void *ptr)
{
	unsigned long flags;
	struct net_device *dev = ptr;
	struct fb_ethtag_private *vdev;
	struct vlinknlmsg vhdr;

	if (!dev)
		return NOTIFY_DONE;
	switch (event) {
	case NETDEV_CHANGE:
		rcu_read_lock();
		list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list)
			if (vdev->real_dev == dev)
				netif_stacked_transfer_operstate(vdev->real_dev,
								 vdev->self);
		rcu_read_unlock();
		break;
	case NETDEV_FEAT_CHANGE:
		/* Nothing right now */
		break;
	case NETDEV_UNREGISTER:
		if (dev->reg_state != NETREG_UNREGISTERING)
			break;

		memset(&vhdr, 0, sizeof(vhdr));
		vhdr.cmd = VLINKNLCMD_RM_DEVICE;
		spin_lock_irqsave(&fb_ethtag_vdevs_lock, flags);
		list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list) {
			if (vdev->real_dev == dev) {
				memset(vhdr.virt_name, 0,
				       sizeof(vhdr.virt_name));
				strlcpy(vhdr.virt_name, vdev->self->name,
					strlen(vdev->self->name));
				fb_ethtag_rm_dev(&vhdr, NULL);
			}
		}
		spin_unlock_irqrestore(&fb_ethtag_vdevs_lock, flags);
		break;
	case NETDEV_PRE_TYPE_CHANGE:
		return NOTIFY_BAD;
	default:
		return NOTIFY_DONE;
	}

	return NOTIFY_DONE;
}

static struct ethtool_ops fb_ethtag_ethtool_ops __read_mostly = {
	.get_link            = ethtool_op_get_link,
	.get_settings        = fb_ethtag_ethtool_get_settings,
	.get_rx_csum         = fb_ethtag_ethtool_get_rx_csum,
	.get_drvinfo         = fb_ethtag_ethtool_get_drvinfo,
	.get_flags           = fb_ethtag_ethtool_get_flags,
};

static struct net_device_ops fb_ethtag_netdev_ops __read_mostly = {
	.ndo_init            = fb_ethtag_init,
	.ndo_uninit          = fb_ethtag_uninit,
	.ndo_open            = fb_ethtag_open,
	.ndo_stop            = fb_ethtag_stop,
	.ndo_start_xmit      = fb_ethtag_start_xmit,
	.ndo_get_stats64     = fb_ethtag_get_stats64,
	.ndo_change_mtu      = eth_change_mtu,
	.ndo_set_mac_address = eth_mac_addr,
	.ndo_validate_addr   = eth_validate_addr,
};

static struct header_ops fb_ethtag_header_ops __read_mostly = {
	.create              = fb_ethtag_create_header,
	.rebuild             = eth_rebuild_header,
	.parse               = eth_header_parse,
	.cache               = eth_header_cache,
	.cache_update        = eth_header_cache_update,
};

static struct rtnl_link_ops fb_ethtag_rtnl_ops __read_mostly = {
	.kind                = "lana",
	.priv_size           = sizeof(struct fb_ethtag_private),
	.setup               = fb_ethtag_dev_setup,
	.validate            = fb_ethtag_validate,
};

static struct vlink_subsys fb_ethtag_sys __read_mostly = {
	.name                = "ch.ethz.csg.ethtagged",
	.owner               = THIS_MODULE,
	.type                = VLINKNLGRP_ETHERNET,
	.rwsem               = __RWSEM_INITIALIZER(fb_ethtag_sys.rwsem),
};

static struct notifier_block fb_ethtag_notifier_block __read_mostly = {
	.notifier_call       = fb_ethtag_dev_event,
};

static struct vlink_callback fb_ethtag_add_dev_cb =
	VLINK_CALLBACK_INIT(fb_ethtag_add_dev, NETLINK_VLINK_PRIO_NORM);
static struct vlink_callback fb_ethtag_rm_dev_cb =
	VLINK_CALLBACK_INIT(fb_ethtag_rm_dev, NETLINK_VLINK_PRIO_NORM);
static struct vlink_callback fb_ethtag_start_hook_dev_cb =
	VLINK_CALLBACK_INIT(fb_ethtag_start_hook_dev, NETLINK_VLINK_PRIO_HIGH);
static struct vlink_callback fb_ethtag_stop_hook_dev_cb =
	VLINK_CALLBACK_INIT(fb_ethtag_stop_hook_dev, NETLINK_VLINK_PRIO_HIGH);

static int __init init_fb_ethtag_module(void)
{
	int ret = 0;
	ret = vlink_subsys_register(&fb_ethtag_sys);
	if (ret)
		return ret;
	vlink_add_callback(&fb_ethtag_sys, &fb_ethtag_add_dev_cb);
	vlink_add_callback(&fb_ethtag_sys, &fb_ethtag_rm_dev_cb);
	vlink_add_callback(&fb_ethtag_sys, &fb_ethtag_start_hook_dev_cb);
	vlink_add_callback(&fb_ethtag_sys, &fb_ethtag_stop_hook_dev_cb);
	ret = rtnl_link_register(&fb_ethtag_rtnl_ops);
	if (ret)	
		goto err;
	register_netdevice_notifier(&fb_ethtag_notifier_block);
	return 0;
err:
	vlink_subsys_unregister_batch(&fb_ethtag_sys);
	return ret;
}

static void __exit cleanup_fb_ethtag_module(void)
{
	struct fb_ethtag_private *vdev;
	rcu_read_lock();
	list_for_each_entry_rcu(vdev, &fb_ethtag_vdevs, list) {
		if (fb_ethtag_real_dev_is_hooked(vdev->real_dev)) {
			rtnl_lock();
			netdev_rx_handler_unregister(vdev->real_dev);
			rtnl_unlock();
			fb_ethtag_make_real_dev_unhooked(vdev->real_dev);
			printk(KERN_INFO "[lana] hook detached from %s\n",
			       vdev->real_dev->name);
		}
		fb_ethtag_rm_dev_common(vdev->self);
	}
	rcu_read_unlock();
	unregister_netdevice_notifier(&fb_ethtag_notifier_block);
	rtnl_link_unregister(&fb_ethtag_rtnl_ops);
	vlink_subsys_unregister_batch(&fb_ethtag_sys);
}

module_init(init_fb_ethtag_module);
module_exit(cleanup_fb_ethtag_module);

MODULE_ALIAS_RTNL_LINK("lana");
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("Ethernet tagged virtual link layer driver");

