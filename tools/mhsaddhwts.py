#!/usr/bin/env python

import sys
import mhs as mhsmodule

DEFAULT_CLK = "clk_100_0000MHzMMCM0"
DEFAULT_RST = "sys_bus_reset"
DEFAULT_MEMFIFO_DEPTH = 128

FSL_VER="2.11.e"

PROC_CONTROL_VER = "1.00.b"
FIFO32_VER = "1.00.a"
FIFO32_ARBITER_VER = "1.00.b"
FIFO32_BURST_CONVERTER_VER = "1.00.b"
XPS_MEM_VER = "1.00.b"



def fifo32(name,rst,depth = DEFAULT_MEMFIFO_DEPTH):
	instance = mhsmodule.MHSPCore("fifo32")
	instance.addEntry("PARAMETER","INSTANCE",name)
	instance.addEntry("PARAMETER","HW_VER",FIFO32_VER)
	instance.addEntry("PARAMETER","C_FIFO32_DEPTH",depth)
	instance.addEntry("BUS_INTERFACE","SFIFO32",name + "_sfifo32")
	instance.addEntry("BUS_INTERFACE","MFIFO32",name + "_mfifo32")
	instance.addEntry("PORT","FIFO32_S_Clk",DEFAULT_CLK)
	instance.addEntry("PORT","FIFO32_M_Clk",DEFAULT_CLK)
	instance.addEntry("PORT","rst",rst)
	return instance
	
def fsl(num,mb_is_slave,rst):
	if mb_is_slave:
		c = "a"
	else:
		c = "b"
	instance = mhsmodule.MHSPCore("fsl_v20")
	name = ("fsl_v20_%d" % num) + c
	instance.addEntry("PARAMETER","INSTANCE",name)
	instance.addEntry("PARAMETER","HW_VER",FSL_VER)
	instance.addEntry("PARAMETER","C_USE_CONTROL",0)
	instance.addEntry("PORT","FSL_Clk",DEFAULT_CLK)
	instance.addEntry("PORT","SYS_Rst",rst)
	if mb_is_slave:
		instance.addEntry("PORT","FSL_Has_Data",name + "_FSL_Has_Data")
	return instance
	
def proc_control(n,mfsl_a,sfsl_a,mfsl_b,sfsl_b,use_mmu):
	instance = mhsmodule.MHSPCore("proc_control")
	instance.addEntry("PARAMETER","INSTANCE","proc_control_0")
	instance.addEntry("PARAMETER","HW_VER",PROC_CONTROL_VER)
	instance.addEntry("PARAMETER","C_ENABLE_ILA",0)
	instance.addEntry("BUS_INTERFACE","SFSLA",sfsl_a)
	instance.addEntry("BUS_INTERFACE","MFSLA",mfsl_a)
	instance.addEntry("BUS_INTERFACE","SFSLB",sfsl_b)
	instance.addEntry("BUS_INTERFACE","MFSLB",mfsl_b)
	instance.addEntry("PORT","Clk",DEFAULT_CLK)
	instance.addEntry("PORT","Rst",DEFAULT_RST)

	if use_mmu:
		instance.addEntry("PORT","pgd","proc_control_0_pgd")
		instance.addEntry("PORT","page_fault","mmu_0_page_fault")
		instance.addEntry("PORT","fault_addr","mmu_0_fault_addr")
		instance.addEntry("PORT","tlb_hits","mmu_0_tlb_hits")
		instance.addEntry("PORT","tlb_misses","mmu_0_tlb_misses")
		instance.addEntry("PORT","retry","proc_control_0_retry")

	for i in range(n):
		instance.addEntry("PORT","reset%X" % i,"proc_control_0_reset%d" % i)
	
	instance.addEntry("PORT","reconos_reset","proc_control_0_reconos_reset")

	return instance
	
def fifo32_arbiter(master_fifos, slave_fifos):
	c = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	instance = mhsmodule.MHSPCore("fifo32_arbiter")
	instance.addEntry("PARAMETER","INSTANCE","fifo32_arbiter_0")
	instance.addEntry("PARAMETER","HW_VER",FIFO32_ARBITER_VER)
	instance.addEntry("PARAMETER","FIFO32_PORTS",len(master_fifos))
	for i in range(len(master_fifos)):
		instance.addEntry("BUS_INTERFACE","MFIFO32_%s" % c[i],master_fifos[i])
		instance.addEntry("BUS_INTERFACE","SFIFO32_%s" % c[i],slave_fifos[i])
	instance.addEntry("BUS_INTERFACE","SFIFO32_MEMCTRL","fifo32_arbiter_0_SFIFO32")
	instance.addEntry("BUS_INTERFACE","MFIFO32_MEMCTRL","fifo32_arbiter_0_MFIFO32")
	instance.addEntry("PORT","Rst","proc_control_0_reconos_reset")
	instance.addEntry("PORT","Clk",DEFAULT_CLK)
	return instance
	
def fifo32_burst_converter():
	instance = mhsmodule.MHSPCore("fifo32_burst_converter")
	instance.addEntry("PARAMETER","INSTANCE","fifo32_burst_converter_0")
	instance.addEntry("PARAMETER","HW_VER",FIFO32_BURST_CONVERTER_VER)
	instance.addEntry("BUS_INTERFACE","SFIFO32_MEMCTRL","fifo32_burst_converter_0_SFIFO32_MEMCTRL")
	instance.addEntry("BUS_INTERFACE","MFIFO32_MEMCTRL","fifo32_burst_converter_0_MFIFO32_MEMCTRL")
	instance.addEntry("BUS_INTERFACE","SFIFO32","fifo32_arbiter_0_SFIFO32")
	instance.addEntry("BUS_INTERFACE","MFIFO32","fifo32_arbiter_0_MFIFO32")
	instance.addEntry("PORT","Rst","proc_control_0_reconos_reset")
	instance.addEntry("PORT","Clk",DEFAULT_CLK)
	return instance

def mmu():
	instance = mhsmodule.MHSPCore("mmu")
	instance.addEntry("PARAMETER","INSTANCE","mmu_0")
	instance.addEntry("PARAMETER","HW_VER","1.00.a")
	instance.addEntry("BUS_INTERFACE","MEM_SFIFO32","mmu_0_MEM_SFIFO32")
	instance.addEntry("BUS_INTERFACE","MEM_MFIFO32","mmu_0_MEM_MFIFO32")
	instance.addEntry("BUS_INTERFACE","HWT_SFIFO32","fifo32_burst_converter_0_SFIFO32_MEMCTRL")
	instance.addEntry("BUS_INTERFACE","HWT_MFIFO32","fifo32_burst_converter_0_MFIFO32_MEMCTRL")
	instance.addEntry("PORT","Rst","proc_control_0_reconos_reset")
	instance.addEntry("PORT","Clk",DEFAULT_CLK)
	instance.addEntry("PORT","PGD","proc_control_0_pgd")
	instance.addEntry("PORT","PAGE_FAULT","mmu_0_page_fault")
	instance.addEntry("PORT","FAULT_ADDR","mmu_0_fault_addr")
	instance.addEntry("PORT","RETRY","proc_control_0_retry")
	instance.addEntry("PORT","TLB_HITS","mmu_0_TLB_HITS")
	instance.addEntry("PORT","TLB_MISSES","mmu_0_TLB_MISSES")
	return instance
	
def hwt(name,num,version="1.00.a"):
	instance = mhsmodule.MHSPCore(name)
	instance.addEntry("PARAMETER","INSTANCE",name + "_%d" % num)
	instance.addEntry("PARAMETER","HW_VER",version)
	instance.addEntry("BUS_INTERFACE","OS_SFSL","fsl_v20_%db" % num)
	instance.addEntry("BUS_INTERFACE","OS_MFSL","fsl_v20_%da" % num)
	instance.addEntry("BUS_INTERFACE","SFIFO32","fifo32_%db_sfifo32" % num)
	instance.addEntry("BUS_INTERFACE","MFIFO32","fifo32_%da_mfifo32" % num)
	instance.addEntry("PORT","Clk",DEFAULT_CLK)
	instance.addEntry("PORT","Rst","proc_control_0_reset%d" % num)

	return instance

def xps_mem(use_mmu):
	instance = mhsmodule.MHSPCore("xps_mem")
	instance.addEntry("PARAMETER","INSTANCE","xps_mem_0")
	instance.addEntry("PARAMETER","HW_VER",XPS_MEM_VER)
	instance.addEntry("BUS_INTERFACE","MPLB","mb_plb")
	if use_mmu:
		instance.addEntry("BUS_INTERFACE","SFIFO32","mmu_0_MEM_SFIFO32")
		instance.addEntry("BUS_INTERFACE","MFIFO32","mmu_0_MEM_MFIFO32")
	else:
		instance.addEntry("BUS_INTERFACE","SFIFO32","fifo32_burst_converter_0_SFIFO32_MEMCTRL")
		instance.addEntry("BUS_INTERFACE","MFIFO32","fifo32_burst_converter_0_MFIFO32_MEMCTRL")

	return instance

def gnd2int():
	instance = mhsmodule.MHSPCore("gnd2int")
	instance.addEntry("PARAMETER","INSTANCE","gnd2int_0")
	instance.addEntry("PARAMETER","HW_VER","1.00.a")
	for i in range(16):
		instance.addEntry("PORT","GND%X" % i,"gnd2int_0_gnd%d" % i)
	return instance

def microblaze(num, osif_fsl_a, osif_fsl_b, memif_fsl_a, memif_fsl_b):
	instance = mhsmodule.MHSPCore("microblaze")
	
	instance.addEntry("PARAMETER","INSTANCE","worker%d" % num)
	instance.addEntry("PARAMETER","HW_VER","8.40.a")
	instance.addEntry("PARAMETER","C_DEBUG_ENABLED","1")
	instance.addEntry("PARAMETER","C_FSL_LINKS","2")
	instance.addEntry("PARAMETER","C_PVR","2")
	instance.addEntry("PARAMETER","C_USE_BARREL","1")
	instance.addEntry("PARAMETER","C_USE_DIV","1")
	instance.addEntry("PARAMETER","C_NUMBER_OF_PC_BRK","1")
	instance.addEntry("PARAMETER","C_NUMBER_OF_RD_ADDR_BRK","0")
	instance.addEntry("PARAMETER","C_NUMBER_OF_WR_ADDR_BRK","0")
	
	
	instance.addEntry("BUS_INTERFACE","SFSL0",osif_fsl_b)
	instance.addEntry("BUS_INTERFACE","MFSL0",osif_fsl_a)
	instance.addEntry("BUS_INTERFACE","DWFSL1","worker%d_DWFSL1"%num)
	instance.addEntry("BUS_INTERFACE","DRFSL1","worker%d_DRFSL1"%num)
	instance.addEntry("BUS_INTERFACE","DLMB","worker%d_lmb_v10_0"%num)
	instance.addEntry("BUS_INTERFACE","ILMB","worker%d_lmb_v10_1"%num)
	instance.addEntry("BUS_INTERFACE","DEBUG","worker%d_debug"%(num))
	
	instance.addEntry("BUS_INTERFACE","DPLB","worker%d_plb"%num)
	instance.addEntry("BUS_INTERFACE","IPLB","worker%d_plb"%num)
	
	instance.addEntry("PORT","MB_RESET","worker%d_reset_MB_Reset"%num)
	instance.addEntry("PORT","INTERRUPT","worker%d_interrupt"%num)
	
	return instance

def fsl2fifo (workernum):
	instance = mhsmodule.MHSPCore("fsl2fifo")
	
	instance.addEntry("PARAMETER","INSTANCE","worker%d_fsl2fifo" % (workernum))
	instance.addEntry("PARAMETER","HW_VER","1.00.c")

	instance.addEntry("BUS_INTERFACE","OS_SFSL","worker%d_DRFSL1" % (workernum))
	instance.addEntry("BUS_INTERFACE","OS_MFSL","worker%d_DWFSL1" % (workernum))
	instance.addEntry("BUS_INTERFACE","SFIFO32","fifo32_%db_sfifo32" % (workernum))
	instance.addEntry("BUS_INTERFACE","MFIFO32","fifo32_%da_mfifo32" % (workernum))

	return instance

def lmb_bram_if_cntrl(workernum, lmbnum):
	instance = mhsmodule.MHSPCore("lmb_bram_if_cntlr")
	
	instance.addEntry("PARAMETER","INSTANCE","worker%d_bram_cntrl_%d" % (workernum, lmbnum))
	instance.addEntry("PARAMETER","HW_VER","3.10.a")
	instance.addEntry("PARAMETER","C_BASEADDR","0x00000000")
	instance.addEntry("PARAMETER","C_HIGHADDR","0x0000FFFF")
	instance.addEntry("PARAMETER","C_NUM_LMB","1")
	
	instance.addEntry("BUS_INTERFACE","SLMB","worker%d_lmb_v10_%d" %(workernum, lmbnum))
	instance.addEntry("BUS_INTERFACE","BRAM_PORT","worker%d_bram_cntlr_%d_BRAM_PORT" %(workernum, lmbnum))
	
	return instance
	
def lmb(workernum, lmbnum):
	instance = mhsmodule.MHSPCore("lmb_v10")

	instance.addEntry("PARAMETER","INSTANCE","worker%d_lmb_v10_%d" % (workernum, lmbnum))
	instance.addEntry("PARAMETER","HW_VER","2.00.b")
	
	instance.addEntry("PORT","SYS_Rst","worker%d_reset_Bus_Struct_Reset" % workernum)
	instance.addEntry("PORT","LMB_Clk","clk_100_0000MHzMMCM0")
	
	return instance

def bram_block(workernum, bramnum):
	instance = mhsmodule.MHSPCore("bram_block")

	instance.addEntry("PARAMETER","INSTANCE","worker%d_bram_block_%d" %( workernum, bramnum))
	instance.addEntry("PARAMETER","HW_VER","1.00.a")
	
	instance.addEntry("BUS_INTERFACE","PORTA","worker%d_bram_cntlr_0_BRAM_PORT" % workernum)
	instance.addEntry("BUS_INTERFACE","PORTB","worker%d_bram_cntlr_1_BRAM_PORT" % workernum)
	
	return instance

def plb_v46(workernum):
	instance = mhsmodule.MHSPCore("plb_v46")
	
	instance.addEntry("PARAMETER","INSTANCE","worker%d_plb" % workernum)
	instance.addEntry("PARAMETER","HW_VER","1.05.a")
	
	instance.addEntry("PORT","SYS_Rst","worker%d_reset_Bus_Struct_Reset" % workernum)
	instance.addEntry("PORT","PLB_Clk","clk_100_0000MHzMMCM0")
	
	return instance

def xps_intc(workernum):
	instance = mhsmodule.MHSPCore("xps_intc")

	instance.addEntry("PARAMETER","INSTANCE","worker%d_intc" % workernum)
	instance.addEntry("PARAMETER","HW_VER","2.01.a")
	instance.addEntry("PARAMETER","C_BASEADDR","0x81800000")
	instance.addEntry("PARAMETER","C_HIGHADDR","0x8180FFFF")
	instance.addEntry("PARAMETER","C_NUM_INTR_INPUTS","0")
	
	instance.addEntry("BUS_INTERFACE","SPLB","worker%d_plb" % workernum)
	
	instance.addEntry("PORT","Intr","" )
	instance.addEntry("PORT","Irq","worker%d_interrupt" % workernum )

	return instance

def proc_sys_reset(workernum):
	instance = mhsmodule.MHSPCore("proc_sys_reset")
	
	instance.addEntry("PARAMETER","INSTANCE","worker%d_reset" % workernum)
	instance.addEntry("PARAMETER","HW_VER","3.00.a")
	
	instance.addEntry("PORT","Slowest_sync_clk","clk_100_0000MHzMMCM0")
	instance.addEntry("PORT","Aux_Reset_In","proc_control_0_reset%d"%workernum)
	instance.addEntry("PORT","MB_Reset","worker%d_reset_MB_Reset"%workernum)
	instance.addEntry("PORT","Dcm_locked","Dcm_all_locked")
	instance.addEntry("PORT","Bus_Struct_Reset","worker%d_reset_Bus_Struct_Reset"%workernum)
	
	return instance

def add_microblaze_subsystem(workernum, mhs):
	# add hardware needed for workercpu
	mhs.addPCore(microblaze(workernum, 
						"fsl_v20_%da" % workernum, "fsl_v20_%db" % workernum, 
						memif_fsl_a="", memif_fsl_b="")
	)
	mhs.addPCore(lmb(workernum, lmbnum=0))
	mhs.addPCore(lmb(workernum, lmbnum=1))
	mhs.addPCore(lmb_bram_if_cntrl(workernum, lmbnum=0))
	mhs.addPCore(lmb_bram_if_cntrl(workernum, lmbnum=1))
	mhs.addPCore(bram_block(workernum, bramnum=0))
	mhs.addPCore(proc_sys_reset(workernum))
	mhs.addPCore(plb_v46(workernum))
	mhs.addPCore(xps_intc(workernum))
	mhs.addPCore(fsl2fifo(workernum))
	# modify hardware in rest of system to accommodate workercpu
	if len(mhs.getPCores("mdm")) == 0:
		print ("No mdm debug cores found! Exiting!")
		sys.exit()
	debug = mhs.getPCores("mdm")[0]
	debug_ports_count = debug.getValue("C_MB_DBG_PORTS")
	debug.setValue("C_MB_DBG_PORTS",str(int(debug_ports_count) + 1))
	#debug.setValue("SPLB","worker%d_plb"%workernum) # last cpu gets acces to debug modules uart 
	debug.addEntry("BUS_INTERFACE","MBDEBUG_%d" % int(debug_ports_count),"worker%d_debug" % (int(debug_ports_count)-1))
 


def print_help():
	sys.stderr.write("Usage: mhsaddhwts.py [-nommu] <system.mhs> <hwt0_directory> <hwt1_directory> ...\n")
	sys.stderr.write("output: The new mhs-file with added ReconOS system and hardware threads.\n")

if __name__=="__main__":
	
	if len(sys.argv) < 3:
		print_help()
		sys.exit(1)
	
	if sys.argv[1] == "-nommu":
		use_mmu = False
		base_design = sys.argv[2]
		hwts = sys.argv[3:]
	else:
		use_mmu = True
		base_design = sys.argv[1]
		hwts = sys.argv[2:]
	
	if len(hwts) > 14:
		sys.stderr.write("More than 14 hardware threads are not supported\n")
		sys.exit(1)
	
	mhs = mhsmodule.MHS(base_design)
	
	
	# Check whether mhs already contains reconos cores
	
	l = mhs.getPCores("xps_mem") + mhs.getPCores("mmu") + mhs.getPCores("fifo32_arbiter") + mhs.getPCores("fsl") + mhs.getPCores("fifo32_burst_converter")
	if len(l) > 0:
		sys.stderr.write("ERROR: mhs file already contains reconos or fsl cores. aborting.\n")
		sys.exit(1)
	
	# check on number of HWTs
	if len(hwts) < 1 or len(hwts) > 14:
		sys.stderr.write("ERROR: you must specify at least 1 and at most 14 hardware threads\n")
		sys.exit(1)
		
	# last 8 characters are treated as version number
	names = map(lambda x: x[:-8],hwts)
	versions = map(lambda x: x[-7:].replace("_","."),hwts)
	
	# insert HWTs:	
	for i in range(len(hwts)):
		if names[i][0:10] == "microblaze":
			add_microblaze_subsystem(i, mhs)
		else:
			mhs.addPCore(hwt(names[i],i,versions[i]))
		
	# insert FSLs:
	for i in range(len(hwts)):
		mhs.addPCore(fsl(i,True ,"proc_control_0_reset%d" % i))
		mhs.addPCore(fsl(i,False,"proc_control_0_reset%d" % i))
	
	mhs.addPCore(fsl(len(hwts),True ,"proc_control_0_reconos_reset"))
	mhs.addPCore(fsl(len(hwts),False,"proc_control_0_reconos_reset"))
	mhs.addPCore(fsl(len(hwts)+1,True ,"proc_control_0_reconos_reset"))
	mhs.addPCore(fsl(len(hwts)+1,False,"proc_control_0_reconos_reset"))	
	
	mb = mhs.getPCores("microblaze")[0]
	mb.setValue("C_FSL_LINKS",len(hwts) + 2)
	mb.setValue("C_STREAM_INTERCONNECT",0)
	for i in range(len(hwts) + 2):
		mb.addEntry("BUS_INTERFACE","SFSL%d" % i,"fsl_v20_%da" % i)
		mb.addEntry("BUS_INTERFACE","MFSL%d" % i,"fsl_v20_%db" % i)
	
		
	#insert memory subsystem
	
	b_fifos = map(lambda x: "fifo32_%db" % x, range(len(hwts)))
	a_fifos = map(lambda x: "fifo32_%da" % x, range(len(hwts)))
	
	for i in range(len(b_fifos)):
		mhs.addPCore(fifo32(b_fifos[i],"proc_control_0_reset%d" % i))
		#mhs.addPCore(fifo32(b_fifos[i],"proc_control_reconos_reset" % i))
	for i in range(len(a_fifos)):
		mhs.addPCore(fifo32(a_fifos[i],"proc_control_0_reset%d" % i))
		#mhs.addPCore(fifo32(a_fifos[i],"proc_control_reconos_reset" % i))
	
	master_fifos = map(lambda x: x + "_mfifo32", b_fifos)
	slave_fifos = map(lambda x: x + "_sfifo32", a_fifos)
	
	mhs.addPCore(fifo32_arbiter(master_fifos, slave_fifos))
	
	mhs.addPCore(fifo32_burst_converter())
	if use_mmu:
		mhs.addPCore(mmu())
	
	mhs.addPCore(xps_mem(use_mmu))
	
	# insert proc_control
	n = len(hwts)
	mhs.addPCore(proc_control(len(hwts),"fsl_v20_%da" % n,"fsl_v20_%db" % n,"fsl_v20_%da" % (n+1),"fsl_v20_%db" % (n+1),use_mmu))
	
	
	# Connect interrupts
	
	mhs.addPCore(gnd2int())
	
	intc = mhs.getPCores("xps_intc")[0]
	interrupts = intc.getValue("Intr")
	
	reconos_int = ""
	
	for i in range(16):
		if i < len(hwts) + 2:
			reconos_int = (" & fsl_v20_%da_FSL_Has_Data" % i) + reconos_int
		else:
			reconos_int = (" & gnd2int_0_gnd%d" % i) + reconos_int	
	
	interrupts = interrupts + reconos_int
	intc.setValue("Intr",interrupts)
	
	# Done
	
	sys.stdout.write(str(mhs))


