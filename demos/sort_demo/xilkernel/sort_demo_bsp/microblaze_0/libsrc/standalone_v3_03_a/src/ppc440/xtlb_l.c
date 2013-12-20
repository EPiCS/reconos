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

#include "xtlb_l.h"
#include "xpseudo_asm.h"
#include "xreg440.h"

/*************************************************************************
*
* Set the Page Identification attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @param    EPN is the Effective Page Number or Virtual address that
*           will be used for this page.  Only the left most 22 bits will 
*           be used and the remaining bits will be masked off and cleared.
*
* @param    Page attributes Valid, Translation Space (TS) and Page Size
*           must be supplied here.  Values that can be ORed together are
*           supplied in xtlb_l.h
*
* @return   None.
*
* @note     According to the PPC440 standards all TLB pages must begin
*           on their natural page boundaries (i.e. a 256MB page must 
*           begin on 0x00000000 or 0x100000000 or ... 0xF00000000).  
*           To adhere to the standard, all bits lower than the natural
*           boundary will be masked off to 0 (i.e. a 256MB page passed
*           in as 0xFFFF0000 will be masked to 0xF0000000).
*
* @note     The value in the MMUCR[STID] will be stored as the Process ID
*           in the TID field of the TLB.
*
*************************************************************************/

void XTlb_SetPageID(unsigned short page, unsigned int EPN, unsigned short attrib)
{
  unsigned int maskedEPN;
  unsigned int size = ((attrib >> 4) & 0x0000000F);

  /* Mask off bits according to size.  The value of size for a 16KB 
   page is 2, therefore 4 extra bits (18:21) are also zeroed out. */
  maskedEPN = EPN & (0xFFFFFC00 << (size+size));

  tlbwe(maskedEPN|(attrib&0x3FF),page,0);
}


/*************************************************************************
*
* Set the Address Translation attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @param    RPN is the Real Page Number that will be used for this page.  
*           Only the left most 22 bits will be used and the remaining bits 
*           will be masked off and cleared .
*
* @param    ERPN is the Extended Real Page Number which is used to supply
*           the remaining four bits above 32 bit addresses.
*
* @param    Page Size must be supplied here to ensure correct masking.
*
* @return   None.
*
* @note     According to the PPC440 standards all RPN values must begin
*           on their natural boundaries (i.e. a 256MB address must 
*           begin on 0x00000000 or 0x100000000 or ... 0xF00000000).  
*           To adhere to the standard, all bits lower than the natural
*           boundary will be masked off to 0 (i.e. a 256MB address passed
*           in as 0xFFFF0000 will be masked to 0xF0000000).
*
*************************************************************************/

void XTlb_SetAddrTxlat(unsigned short page, unsigned int RPN, unsigned char ERPN, unsigned short Psize)
{
  unsigned int maskedRPN, maskedERPN;
  unsigned int size = ((Psize >> 4) & 0xF);

  /* If page size < 4GB (less than 32 bits).  Mask off extra bits as is
     done in XTlb_SetPageID */
  if(size<11) {
    maskedRPN = (RPN & (0xFFFFFC00 << (size+size)));
    maskedERPN = ERPN;
  }
  else
  {
    size = size - 11;
    maskedRPN = 0;
    maskedERPN = (ERPN&(0xF << (size+size)))&0xF;
  }

  tlbwe(maskedRPN|maskedERPN,page,1);
}


/*************************************************************************
*
* Set the Storage Control and Access control attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @param    Attributes: User and Supervisor Read Write and Execute 
*           permissions, User Defined values, Cacheability, Cache
*           Write-through control, Guarded pages, and Memory Endianess
*           are controlled here.  Values can be found in xtlb_l.h and
*           must be ORed together
*
* @return   None.
*
*************************************************************************/

void XTlb_SetStorAttribAccessCtrl(unsigned short page, unsigned short attrib)
{
  tlbwe((attrib&0xFFFF),page,2);
}

/*************************************************************************
*
* Commit TLB entry changes and make them go into effect.
*
* @param    None.
*
* @return   None.
*
* @note     This function must be called prior to the page being used.
*           Multiple pages can be setup prior to calling this as long as
*           nothing interrupts the TLB setup and the page is not
*           used prior to commit being called.  If only one set of 
*           attributes are to be changed on a page, then commit must also
*           be called to ensure the page changes go into effect correctly.
*
*************************************************************************/

void XTlb_Commit(void)
{
  isync;
}


/*************************************************************************
*
* Completely erase a TLB Page
*
* @param    Page (0-63) to be erased
*
* @return   None.
*
* @note     This function will set all fields of the TLB entry to zero
*           which as a side effect will invalidate it.  Commit must be 
*           called to ensure erase goes into effect.
*
*************************************************************************/

void XTlb_ErasePage(unsigned short page)
{
  tlbwe(0,page,0);
  tlbwe(0,page,1);
  tlbwe(0,page,2);
}


/*************************************************************************
*
* Find the first free TLB Page
*
* @param    None.
*
* @return   Page number (aka index) of first free page that doesn't have
*           the valid bit set, -1 if no page can be found.
*
*************************************************************************/

short XTlb_GetFreePage(void)
{
  int i;
  unsigned int tlbEntry;

  for(i=0; i<64; i++) {
    tlbEntry = tlbre(i,0);
    sync;
    if(!(XTLB_VALID_PAGE & tlbEntry))
      break;
  }
  return (i<64) ? i : -1;
}


/*************************************************************************
*
* Find the entry according to the parameters found
*
* @param    A base address to be used in the search.  This address does 
*           not have to be masked off as is needed in setting up the 
*           TLB entries.
*
* @param    Process ID which will be used to match the TID field.
*
* @param    The Translation Space (TS)
*
* @return   Page number (aka index) of the page if one is found.  -1 if 
*           no match is found.
*
* @note     Due to the nature of TLB Page lookup it is only possible to 
*           search for pages that exist for the current PID or globally
*           (PID=0)
*
*************************************************************************/

short XTlb_FindPage(unsigned int address, unsigned char PID, unsigned char TS)
{
  unsigned int MMUCR, index, cr;

  /* Save off old MMUCR */
  MMUCR = mfspr(XREG_SPR_MMUCR);

  /* Set MMUCR[STID] field for tlbsx. function */
  mtspr(XREG_SPR_MMUCR,(MMUCR&0xFFFEFF00)|PID|(TS<<16));

  index = tlbsx(address,0); 

  /* Put old MMUCR back */
  mtspr(XREG_SPR_MMUCR,MMUCR);
  
  /* Grab Condition Register to see if entry was found */
  cr = mfcr();

  return (0x20000000&cr) ? index : -1;
}


/*************************************************************************
*
* Get the Page Identification attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @return   Page ID attributes of the requested page
*
*************************************************************************/

unsigned int XTlb_GetPageID(unsigned short page)
{
  unsigned int tlbWord;
  
  tlbWord = tlbre(page,0);
  sync;
  return tlbWord;
}

/*************************************************************************
*
* Get the Address Translation attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @return   Address Translation attributes of the requested page
*
*************************************************************************/

unsigned int XTlb_GetAddrTxlat(unsigned short page)
{
  unsigned int tlbWord;
  
  tlbWord = tlbre(page,1);
  sync;
  return tlbWord;
}

/*************************************************************************
*
* Get the Storage and Access Control attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @return   Storage and Access Control attributes of the requested page
*
*************************************************************************/

unsigned int XTlb_GetStorAttribAccessCtrl(unsigned short page)
{
  unsigned int tlbWord;
  
  tlbWord = tlbre(page,2);
  sync;
  return tlbWord;
}

/*************************************************************************
*
* Get all attributes for the TLB Page.
*
* @param    Page (0-63) that the attributes are being set for.  
*
* @return   All attributes of the requested page
*
*************************************************************************/

XTlbPage XTlb_GetAllPageAttrib(unsigned short page)
{
  XTlbPage tlbEntry;

  tlbEntry.PageID = tlbre(page,0);
  tlbEntry.AddrTxlat = tlbre(page,1);
  tlbEntry.StorAttribAccessCtrl = tlbre(page,2);
  sync;

  return tlbEntry;
}
