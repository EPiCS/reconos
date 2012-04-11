#include <linux/module.h>

#include "reconos.h"

static int __init init_reconos_module(void)
{
	return 0;
}

static void __exit cleanup_reconos_module(void)
{
}

module_init(init_reconos_module);
module_exit(cleanup_reconos_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("ReconOS lib module");
