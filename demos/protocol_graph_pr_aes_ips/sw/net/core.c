/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <net/net_namespace.h>

#include "xt_fblock.h"
#include "xt_vlink.h"
#include "xt_engine.h"

struct proc_dir_entry *lana_proc_dir;
EXPORT_SYMBOL(lana_proc_dir);
struct proc_dir_entry *fblock_proc_dir;
EXPORT_SYMBOL(fblock_proc_dir);

static int __init init_lana_core_module(void)
{
	int ret;

	printk(KERN_INFO "[lana] bootstrapping core ...\n");

	lana_proc_dir = proc_mkdir("lana", init_net.proc_net);
	if (!lana_proc_dir)
		return -ENOMEM;
	fblock_proc_dir = proc_mkdir("fblock", lana_proc_dir);
	if (!fblock_proc_dir)
		goto err;
	ret = init_vlink_system();
	if (ret)
		goto err1;
	ret = init_fblock_tables();
	if (ret)
		goto err2;
	ret = init_fblock_builder();
	if (ret)
		goto err3;
	ret = init_fblock_userctl_system();
	if (ret)
		goto err4;
	ret = init_engine();
	if (ret)
		goto err5;
	ret = init_ei_conf();
	if (ret)
		goto err6;
	ret = init_hwif();
	if (ret)
		goto err7;

	printk(KERN_INFO "[lana] core up and running!\n");
	return 0;

err7:
	cleanup_ei_conf();
err6:
	cleanup_engine();
err5:
	cleanup_fblock_userctl_system();
err4:
	cleanup_fblock_builder();
err3:
	cleanup_fblock_tables();
err2:
	cleanup_vlink_system();
err1:
	remove_proc_entry("fblock", lana_proc_dir);
err:
	remove_proc_entry("lana", init_net.proc_net);
	return -ENOMEM;
}

static void __exit cleanup_lana_core_module(void)
{
	printk(KERN_INFO "[lana] halting core ...\n");

	cleanup_fblock_userctl_system();
	cleanup_fblock_tables();
	cleanup_fblock_builder();
	cleanup_vlink_system();
	cleanup_engine();
	cleanup_ei_conf();
	cleanup_hwif();

	remove_proc_entry("fblock", lana_proc_dir);
	remove_proc_entry("lana", init_net.proc_net);

	printk(KERN_INFO "[lana] core shut down!\n");
}

module_init(init_lana_core_module);
module_exit(cleanup_lana_core_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA core driver");
