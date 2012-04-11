#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>

#include "reconos.h"
#include "mbox.h"

static struct mbox mb;

static struct reconos_hwt hwt;

static struct reconos_resource res = {
	.type = RECONOS_TYPE_MBOX,
	.ptr = &mb,
};

static uint32_t init_data = 0xDEADBEEF;

static int __init init_reconos_test_module(void)
{
	uint32_t ret = 0;

	mbox_init(&mb, 3);

	reconos_init_autodetect();
	reconos_hwt_setresources(&hwt, &res, 1);
	reconos_hwt_setinitdata(&hwt, (void *) init_data);
	reconos_hwt_create(&hwt, 0, NULL);

	ret = mbox_get(&mb);
	if (ret == init_data)
		printk(KERN_INFO "[reconos-test] get_init_data: "
		       "success (%X=%X)\n", init_data, ret);
	else
		printk(KERN_INFO "[reconos-test] get_init_data: "
		       "failure (%X!=%X)\n", init_data, ret);

	kthread_stop(hwt.delegate);
	reconos_cleanup();

	printk("[reconos-test] loaded, test done\n");
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
