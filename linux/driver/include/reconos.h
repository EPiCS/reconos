/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Linux Driver - ReconOS
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Driver for the ReconOS system. It includes the drivers
 *                 for the OSIFs (AXI FIFO), the interrupt controller and
 *                 the proc control.
 *
 * ======================================================================
 */

#include <linux/ioctl.h>

#define RECONOS_IOC_MAGIC       'k'

#define RECONOS_OSIF_INTC_WAIT    _IOW(RECONOS_IOC_MAGIC, 20, unsigned int)

#define RECONOS_PROC_CONTROL_GET_NUM_HWTS      _IOR(RECONOS_IOC_MAGIC, 1, int)
#define RECONOS_PROC_CONTROL_GET_TLB_HITS      _IOR(RECONOS_IOC_MAGIC, 2, int)
#define RECONOS_PROC_CONTROL_GET_TLB_MISSES    _IOR(RECONOS_IOC_MAGIC, 3, int)
#define RECONOS_PROC_CONTROL_GET_FAULT_ADDR    _IOR(RECONOS_IOC_MAGIC, 4, unsigned int)
#define RECONOS_PROC_CONTROL_CLEAR_PAGE_FAULT  _IO(RECONOS_IOC_MAGIC, 5)
#define RECONOS_PROC_CONTROL_SET_PGD_ADDR      _IO(RECONOS_IOC_MAGIC, 6)
#define RECONOS_PROC_CONTROL_SYS_RESET         _IO(RECONOS_IOC_MAGIC, 7)
#define RECONOS_PROC_CONTROL_SET_HWT_RESET     _IOW(RECONOS_IOC_MAGIC, 8, int)
#define RECONOS_PROC_CONTROL_CLEAR_HWT_RESET   _IOW(RECONOS_IOC_MAGIC, 9, int)
#define RECONOS_PROC_CONTROL_DO_PTW            _IOW(RECONOS_IOC_MAGIC, 10, void*)
#define RECONOS_PROC_CONTROL_CACHE_FLUSH       _IO(RECONOS_IOC_MAGIC, 11)
