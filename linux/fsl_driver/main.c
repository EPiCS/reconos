///
/// \file main.c
///
/// This file is part of the reconos device driver.
/// 
/// This driver provides character devices (e.g. /dev/osifnnn) for
/// accessing ReconOS OSIF registers from user space, in particular
/// from a delegate thread. The driver also provides access to TLB
/// registers via /dev/tlb[0,1...].
/// 
/// \author     Andreas Agne <agne@upb.de>
/// \date       22.08.2010
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
// Major Changes:
// 
// 15.01.2008   Andreas Agne   File created

#include <linux/autoconf.h>
#include <linux/module.h>

#include <asm/dcr.h>

#include "reconos.h"

/* Match table for of_platform binding */
static const struct of_device_id __devinitconst osif_of_match[] = {
        { .compatible = "xlnx,osif-2.01.a", .data = NULL },
        { .compatible = "xlnx,plb-osif-2.01.a", .data = NULL},
 	{ .compatible = "xlnx,osif-2.03.a", .data = NULL},
	{ .compatible = "xlnx,plb-osif-2.03.a", .data = NULL},
	{},
};


struct of_platform_driver osif_of_driver = {
        .owner = THIS_MODULE,
	.name = "osif",
        .match_table = osif_of_match,

	.probe = osif_of_probe,
	.remove = __devexit_p(osif_of_remove),
        .driver = {
            .name = "osif"
        }
};

/* Match table for of_platform binding */
static const struct of_device_id __devinitconst tlb_of_match[] = {
	{ .compatible = "xlnx,tlb", .data = NULL },
	{},
};

struct of_platform_driver tlb_of_driver = {
	.owner = THIS_MODULE,
	.name = "reconos_tlb",
	.match_table = tlb_of_match,

	.probe = tlb_of_probe,
	.remove = __devexit_p(tlb_of_remove),
	.driver = {
		.name = "reconos_tlb"
	}
};


int __init reconos_init(void) {
	int result;
	dev_t dev = 0;

	PDEBUG("registering device\n");

	if (osif_major) {
		dev = MKDEV(osif_major, osif_minor);
		result = register_chrdev_region(dev, osif_numslots, "osif");
	} else {    // dynamic allocation of device numbers
		result = alloc_chrdev_region(&dev, osif_minor, osif_numslots, "osif");
		osif_major = MAJOR(dev);
	}

	if (result < 0) {
		printk(KERN_WARNING "osif: can't get major %d\n", osif_major);
		return result;
	}

	if (tlb_major) {
		dev = MKDEV(tlb_major, tlb_minor);
		result = register_chrdev_region(dev, tlb_numtlbs, "tlb");
	} else {    // dynamic allocation of device numbers
		result = alloc_chrdev_region(&dev, tlb_minor, tlb_numtlbs, "tlb");
		tlb_major = MAJOR(dev);
	}


	if (result < 0) {
		printk(KERN_WARNING "tlb: can't get major %d\n", osif_major);
		return result;
	}

	//    PDEBUG("registered up to %d char devices with major %d\n", osif_numslots, osif_major);

	result = of_register_platform_driver(&osif_of_driver);
	if (result) {
		printk(KERN_ERR "osif: of_register_platform_driver() failed\n");
		return result;
	}

	result = of_register_platform_driver(&tlb_of_driver);
	if (result) {
		printk(KERN_ERR "tlb: of_register_platform_driver() failed\n");
		return result;
	}

	return result;
}

void __exit reconos_cleanup(void) {
	dev_t osif_dev = MKDEV(osif_major, osif_minor);
	dev_t tlb_dev = MKDEV(tlb_major, tlb_minor);

	unregister_chrdev_region(osif_dev, osif_numslots);
	unregister_chrdev_region(tlb_dev, tlb_numtlbs);

	PDEBUG("unregistered all char devices\n");

	of_unregister_platform_driver(&osif_of_driver);
	of_unregister_platform_driver(&tlb_of_driver);

	PDEBUG("unregistered of platform driver\n");
}


module_init(reconos_init);
module_exit(reconos_cleanup);

