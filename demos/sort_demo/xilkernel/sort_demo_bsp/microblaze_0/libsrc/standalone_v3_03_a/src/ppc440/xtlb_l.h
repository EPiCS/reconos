/*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"    */
/*     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR          */
/*     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION  */
/*     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION      */
/*     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS        */
/*     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,          */
/*     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE */
/*     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY         */
/*     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE          */
/*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR   */
/*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF  */
/*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS  */
/*     FOR A PARTICULAR PURPOSE.                                        */
/*                                                                      */
/*     (c) Copyright 2006 Xilinx, Inc.                                  */
/*     All rights reserved.                                             */

#ifdef CACHE_H
#warning Use of XCache and XTlb together can cause programming errors.
#endif

#ifndef TLB_H
#define TLB_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  unsigned int PageID;
  unsigned int AddrTxlat;
  unsigned int StorAttribAccessCtrl;
} XTlbPage;

/* Access Control Fields */
#define XTLB_USER_R       0x00000008
#define XTLB_USER_W       0x00000010
#define XTLB_USER_X       0x00000020
#define XTLB_USER_RW      0x00000018
#define XTLB_USER_RX      0x00000028
#define XTLB_USER_WX      0x00000030
#define XTLB_USER_RWX     0x00000038
#define XTLB_SUP_R        0x00000001
#define XTLB_SUP_W        0x00000002
#define XTLB_SUP_X        0x00000004
#define XTLB_SUP_RW       0x00000003
#define XTLB_SUP_RX       0x00000005
#define XTLB_SUP_WX       0x00000006
#define XTLB_SUP_RWX      0x00000007

/* Storage Control Fields */
#define XTLB_USER_0       0x00008000
#define XTLB_USER_1       0x00004000
#define XTLB_USER_2       0x00002000
#define XTLB_USER_3       0x00001000
#define XTLB_WR_THRU      0x00000800
#define XTLB_NO_CACHE     0x00000400
#define XTLB_GUARDED      0x00000100
#define XTLB_LIL_ENDIAN   0x00000080

/* Page Identification Fields*/
#define XTLB_VALID_PAGE   0x00000200
#define XTLB_SET_TS       0x00000100
#define XTLB_1KB_PAGE     0x00000000
#define XTLB_4KB_PAGE     0x00000010
#define XTLB_16KB_PAGE    0x00000020
#define XTLB_64KB_PAGE    0x00000030
#define XTLB_256KB_PAGE   0x00000040
#define XTLB_1MB_PAGE     0x00000050
#define XTLB_16MB_PAGE    0x00000070
#define XTLB_256MB_PAGE   0x00000090

void XTlb_SetPageID(unsigned short page, unsigned int EPN, unsigned short attrib);

void XTlb_SetAddrTxlat(unsigned short page, unsigned int RPN, unsigned char ERPN, unsigned short Psize);

void XTlb_SetStorAttribAccessCtrl(unsigned short page, unsigned short attrib);

void XTlb_Commit(void);

void XTlb_ErasePage(unsigned short page);

short XTlb_GetFreePage(void);

short XTlb_FindPage(unsigned int address, unsigned char PID, unsigned char TS);

unsigned int XTlb_GetPageID(unsigned short page);

unsigned int XTlb_GetAddrTxlat(unsigned short page);

unsigned int XTlb_GetStorAttribAccessCtrl(unsigned short page);

XTlbPage XTlb_GetAllPageAttrib(unsigned short page);


#ifdef __cplusplus
}
#endif

#endif
