/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/socket.h>
#include <linux/slab.h>
#include <linux/net.h>
#include <linux/skbuff.h>
#include <linux/proc_fs.h>
#include <net/netlink.h>
#include <net/sock.h>

#include "xt_vlink.h"

static DEFINE_MUTEX(vlink_mutex);
static struct sock *vlink_sock = NULL;
static struct vlink_subsys **vlink_subsystem_table = NULL;
extern struct proc_dir_entry *lana_proc_dir;
static struct proc_dir_entry *vlink_proc;

void vlink_lock(void)
{
	mutex_lock(&vlink_mutex);
}
EXPORT_SYMBOL_GPL(vlink_lock);

void vlink_unlock(void)
{
	mutex_unlock(&vlink_mutex);
}
EXPORT_SYMBOL_GPL(vlink_unlock);

int vlink_subsys_register(struct vlink_subsys *n)
{
	int i, slot;
	struct vlink_subsys *vs;

	if (!n)
		return -EINVAL;
	vlink_lock();
	for (i = 0, slot = -1; i < MAX_VLINK_SUBSYSTEMS; ++i) {
		if (!vlink_subsystem_table[i] && slot == -1)
			slot = i;
		else if (!vlink_subsystem_table[i])
			continue;
		else {
			vs = vlink_subsystem_table[i];
			if (n->type == vs->type) {
				vlink_unlock();
				return -EBUSY;
			}
		}
	}
	if (slot != -1) {
		n->id = slot;
		vlink_subsystem_table[slot] = n;
		__module_get(THIS_MODULE);
	}
	vlink_unlock();
	return slot == -1 ? -ENOMEM : 0;
}
EXPORT_SYMBOL_GPL(vlink_subsys_register);

void vlink_subsys_unregister(struct vlink_subsys *n)
{
	int i;
	if (!n)
		return;
	vlink_lock();
	for (i = 0; i < MAX_VLINK_SUBSYSTEMS; ++i) {
		if (vlink_subsystem_table[i] == n && i == n->id) {
			vlink_subsystem_table[i] = NULL;
			n->id = 0;
			module_put(THIS_MODULE);
			break;
		}
	}
	vlink_unlock();
}
EXPORT_SYMBOL_GPL(vlink_subsys_unregister);

static struct vlink_subsys *__vlink_subsys_find(u16 type)
{
	int i;
	for (i = 0; i < MAX_VLINK_SUBSYSTEMS; ++i)
		if (vlink_subsystem_table[i])
			if (vlink_subsystem_table[i]->type == type)
				return vlink_subsystem_table[i];
	return NULL;
}

struct vlink_subsys *vlink_subsys_find(u16 type)
{
	struct vlink_subsys *ret;
	vlink_lock();
	ret = __vlink_subsys_find(type);
	vlink_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(vlink_subsys_find);

static int __vlink_add_callback(struct vlink_subsys *n,
				struct vlink_callback *cb)
{
	struct vlink_callback **hb;

	if (!cb)
		return -EINVAL;
	hb = &n->head;
	while (*hb != NULL) {
		if (cb->priority > (*hb)->priority)
			break;
		hb = &((*hb)->next);
	}
	cb->next = *hb;
	*hb = cb;
	return 0;
}

int vlink_add_callback(struct vlink_subsys *n,
		       struct vlink_callback *cb)
{
	int ret;

	if (!n)
		return -EINVAL;
	down_write(&n->rwsem);
	ret = __vlink_add_callback(n, cb);
	up_write(&n->rwsem);

	return ret;
}
EXPORT_SYMBOL_GPL(vlink_add_callback);

int vlink_add_callbacks_va(struct vlink_subsys *n,
			   struct vlink_callback *cb, va_list ap)
{
	int ret = 0;
	struct vlink_callback *arg;

	arg = cb;
	while (arg) {
		ret = vlink_add_callback(n, arg);
		if (ret)
			break;
		arg = va_arg(ap, struct vlink_callback *);
	}

	return ret;
}
EXPORT_SYMBOL_GPL(vlink_add_callbacks_va);

int vlink_add_callbacks(struct vlink_subsys *n,
			struct vlink_callback *cb, ...)
{
	int ret;
	va_list vl;

	va_start(vl, cb);
	ret = vlink_add_callbacks_va(n, cb, vl);
	va_end(vl);

	return ret;
}
EXPORT_SYMBOL_GPL(vlink_add_callbacks);

static int __vlink_rm_callback(struct vlink_subsys *n,
			       struct vlink_callback *cb)
{
	struct vlink_callback **hb;

	if (!cb)
		return -EINVAL;
	hb = &n->head;
	while (*hb != NULL) {
		if (*hb == cb) {
			*hb = cb->next;
			return 0;
		}
		hb = &((*hb)->next);
	}

	return -ENOENT;
}

int vlink_rm_callback(struct vlink_subsys *n,
		      struct vlink_callback *cb)
{
	int ret;
	if (!n)
		return -EINVAL;
	down_write(&n->rwsem);
	ret = __vlink_rm_callback(n, cb);
	up_write(&n->rwsem);
	return ret;
}
EXPORT_SYMBOL_GPL(vlink_rm_callback);

void vlink_subsys_unregister_batch(struct vlink_subsys *n)
{
	int i;

	if (!n)
		return;
	vlink_lock();
	for (i = 0; i < MAX_VLINK_SUBSYSTEMS; ++i) {
		if (vlink_subsystem_table[i] == n && i == n->id) {
			vlink_subsystem_table[i] = NULL;
			n->id = 0;
			module_put(THIS_MODULE);
			break;
		}
	}
	vlink_unlock();
	while (n-> head != NULL)
		vlink_rm_callback(n, n->head);
}
EXPORT_SYMBOL_GPL(vlink_subsys_unregister_batch);

static int __vlink_invoke(struct vlink_subsys *n,
			  struct vlinknlmsg *vmsg,
			  struct nlmsghdr *nlh)
{
	int ret = 0, nret;
	struct vlink_callback *hb, *hn;

	hb = n->head;
	while (hb) {
		hn = hb->next;
		nret = 0;
		ret = hb->rx(vmsg, nlh);
		if ((ret & NETLINK_VLINK_RX_EMERG) == NETLINK_VLINK_RX_EMERG ||
		    (nret = (ret & NETLINK_VLINK_RX_STOP) == NETLINK_VLINK_RX_STOP)) {
			if (vmsg->cmd == VLINKNLCMD_START_HOOK_DEVICE && nret)
				__module_get(n->owner);
			if (vmsg->cmd == VLINKNLCMD_STOP_HOOK_DEVICE && nret)
				module_put(n->owner);
			break;
		}
		hb = hn;
	}

	return ret;
}

static int __vlink_rcv(struct sk_buff *skb, struct nlmsghdr *nlh)
{
	int ret;
	struct vlinknlmsg *vmsg;
	struct vlink_subsys *sys;

	if (security_netlink_recv(skb, CAP_NET_ADMIN))
		return -EPERM;

	if (nlh->nlmsg_len < NLMSG_LENGTH(sizeof(struct vlinknlmsg)))
		return 0;

	sys = __vlink_subsys_find(nlh->nlmsg_type);
	if (!sys)
		return -EINVAL;

	vmsg = NLMSG_DATA(nlh);

	down_read(&sys->rwsem);
	ret = __vlink_invoke(sys, vmsg, nlh);
	up_read(&sys->rwsem);

	return ret;
}

static void vlink_rcv(struct sk_buff *skb)
{
	vlink_lock();
	netlink_rcv_skb(skb, &__vlink_rcv);
	vlink_unlock();
}

int vlink_procfs_props(char *buff, size_t len)
{
	int i;
	size_t curr = 0;

	//XXX: fits into buff?
	memset(buff, 0, len);
	vlink_lock();
	for (i = 0; i < MAX_VLINK_SUBSYSTEMS && curr < len; ++i) {
		if (vlink_subsystem_table[i]) {
			curr += sprintf(buff + curr, "%s []\n",
					vlink_subsystem_table[i]->name);
		}
	}
	vlink_unlock();
	buff[len - 1] = 0;

	return curr;
}
EXPORT_SYMBOL(vlink_procfs_props);

static int vlink_procfs(char *page, char **start, off_t offset,
			int count, int *eof, void *data)
{
	int i;
	off_t len = 0;

	len += sprintf(page + len, "name|type|id\n");

	vlink_lock();
	for (i = 0; i < MAX_VLINK_SUBSYSTEMS; ++i) {
		if (vlink_subsystem_table[i])
			len += sprintf(page + len, "%s %u %u\n",
				       vlink_subsystem_table[i]->name,
				       vlink_subsystem_table[i]->type,
				       vlink_subsystem_table[i]->id);
	}
	vlink_unlock();

	/* FIXME: fits in page? */
	*eof = 1;
	return len;
}

int init_vlink_system(void)
{
	int ret;

	vlink_subsystem_table = kzalloc(sizeof(*vlink_subsystem_table) *
					MAX_VLINK_SUBSYSTEMS, GFP_KERNEL);
	if (!vlink_subsystem_table)
		return -ENOMEM;
	vlink_sock = netlink_kernel_create(&init_net, NETLINK_VLINK,
					   VLINKNLGRP_MAX, vlink_rcv,
					   NULL, THIS_MODULE);
	if (!vlink_sock) {
		ret = -ENOMEM;
		goto err;
	}
	vlink_proc = create_proc_read_entry("vlink", 0400, lana_proc_dir,
					    vlink_procfs, NULL);
	if (!vlink_proc)
		goto err2;
	return 0;
err2:
	netlink_kernel_release(vlink_sock);
err:
	kfree(vlink_subsystem_table);
	return ret;
}

void cleanup_vlink_system(void)
{
	remove_proc_entry("vlink", lana_proc_dir);
	netlink_kernel_release(vlink_sock);
	kfree(vlink_subsystem_table);
}
