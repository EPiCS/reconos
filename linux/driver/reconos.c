/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Linux Driver - OSIF (AXI FIFO)
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Driver for the entire ReconOS system including the
 *                 OSIFs and the proc control.
 *
 * ======================================================================
 */

#include "reconos.h"

#include "osif.h"
#include "proc_control.h"


// extern variables available in the entire module
int NUM_HWTS = 0;

static __init int reconos_init(void) {
	__printk(KERN_INFO "[reconos] initizializing driver ...\n");

	proc_control_init();

	if (osif_init() < 0)
		goto osif_failed;

	goto out;

osif_failed:
	proc_control_exit();
	return -1;

out:
	return 0;
}

static __exit void reconos_exit(void) {
	__printk(KERN_INFO "[reconos] removing driver ...\n");

	osif_exit();
	proc_control_exit();

	return;
}

module_init(reconos_init);
module_exit(reconos_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Christoph Rüthing <ruething@mail.upb.de>");
