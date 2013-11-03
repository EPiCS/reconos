/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef XT_VLINK_H
#define XT_VLINK_H

#ifdef __KERNEL__

#include <linux/types.h>
#include <linux/rwsem.h>
#include <linux/netlink.h>
#include <linux/module.h>
#include <linux/if.h>

#define NETLINK_VLINK_RX_OK     0  /* Receive went okay, notify next     */
#define NETLINK_VLINK_RX_NXT    1  /* Receive is not for us, notify next */
#define NETLINK_VLINK_RX_BAD    2  /* Receive failed, notify next        */
#define NETLINK_VLINK_RX_EMERG  3  /* Receive failed, do not notify next */
#define NETLINK_VLINK_RX_STOP   4  /* Receive went okay, but still stop  */

#define NETLINK_VLINK_PRIO_LOW  0  /* Low priority callbacks             */
#define NETLINK_VLINK_PRIO_NORM 1  /* Normal priority callbacks          */
#define NETLINK_VLINK_PRIO_HIGH 2  /* High priority callbacks            */

#endif /* __KERNEL__ */

#define NETLINK_VLINK          23  /* Netlink hook type                  */

enum vlink_groups {
	VLINKNLGRP_NONE = NLMSG_MIN_TYPE, /* Reserved                    */
#define VLINKNLGRP_NONE         VLINKNLGRP_NONE
	VLINKNLGRP_ETHERNET,       /* To vlink Ethernet type             */
#define VLINKNLGRP_ETHERNET     VLINKNLGRP_ETHERNET
	VLINKNLGRP_BLUETOOTH,      /* To vlink Bluetooth type            */
#define VLINKNLGRP_BLUETOOTH    VLINKNLGRP_BLUETOOTH
	VLINKNLGRP_INFINIBAND,     /* To vlink InfiniBand type           */
#define VLINKNLGRP_INFINIBAND   VLINKNLGRP_INFINIBAND
	VLINKNLGRP_I2C,            /* To vlink I^2C type                 */
#define VLINKNLGRP_I2C          VLINKNLGRP_I2C
	VLINKNLGRP_SOCKET,         /* To vlink socket type                 */
#define VLINKNLGRP_SOCKET       VLINKNLGRP_SOCKET
	__VLINKNLGRP_MAX
};
#define VLINKNLGRP_MAX          (__VLINKNLGRP_MAX - 1)

enum vlink_cmd {
	VLINKNLCMD_ADD_DEVICE,
	VLINKNLCMD_RM_DEVICE,
	VLINKNLCMD_START_HOOK_DEVICE,
	VLINKNLCMD_STOP_HOOK_DEVICE,
};

/* Generic vlinkmsg header, private data can be appended after the header */
struct vlinknlmsg {
	uint32_t cmd:8,
		 flags:16,
		 reserved:8;
	uint32_t type:16,
		 port:16; /* Actually 8 Bit, but for alignment reasons */
	uint8_t virt_name[IFNAMSIZ];
	uint8_t real_name[IFNAMSIZ];
};

#ifdef __KERNEL__

#define MAX_VLINK_SUBSYSTEMS  256

struct vlink_callback {
	int priority;
	int (*rx)(struct vlinknlmsg *vhdr, struct nlmsghdr *nlh);
	struct vlink_callback *next;
};

#define VLINK_CALLBACK_INIT(fct, prio) {		\
	.rx = (fct),					\
	.priority = (prio),				\
	.next = NULL, }

struct vlink_subsys {
	char *name;
	u32 type:16,
	    id:16;
	struct module *owner;
	struct rw_semaphore rwsem;
	struct vlink_callback *head;
};

#define VLINK_SUBSYS_INIT(varname, sysname, gtype) {	\
	.name = (sysname),				\
	.type = (gtype),				\
	.rwsem = __RWSEM_INITIALIZER((varname).rwsem),	\
	.head = NULL, }

extern int init_vlink_system(void);
extern void cleanup_vlink_system(void);
extern void vlink_lock(void);
extern void vlink_unlock(void);
extern int vlink_subsys_register(struct vlink_subsys *n);
extern void vlink_subsys_unregister(struct vlink_subsys *n);
extern void vlink_subsys_unregister_batch(struct vlink_subsys *n);
extern struct vlink_subsys *vlink_subsys_find(u16 type);
extern int vlink_add_callback(struct vlink_subsys *n,
			      struct vlink_callback *cb);
extern int vlink_add_callbacks(struct vlink_subsys *n,
			       struct vlink_callback *cb, ...);
extern int vlink_add_callbacks_va(struct vlink_subsys *n,
			          struct vlink_callback *cb,
			          va_list ap);
extern int vlink_rm_callback(struct vlink_subsys *n,
			     struct vlink_callback *cb);
extern int vlink_procfs_props(char *buff, size_t len);

#endif /* __KERNEL__ */
#endif /* XT_VLINK_H */
