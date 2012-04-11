#include <linux/kernel.h>
#include <linux/module.h>

#include "reconos.h"
#include "mbox.h"

static int __init init_reconos_test_module(void)
{
	printk("[reconos-test] loaded\n");
	return 0;
}

static void __exit cleanup_reconos_test_module(void)
{
	printk("[reconos-test] unloaded\n");
}

module_init(init_reconos_test_module);
module_exit(cleanup_reconos_test_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("ReconOS lib test module");
