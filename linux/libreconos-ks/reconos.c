/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2012 Andreas Agne <agne@upb.de>
 */

#include <linux/module.h>

#include "reconos.h"

extern uint32_t fsl_read_word(int num);
extern ssize_t fsl_write_word(int num, uint32_t val);

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
