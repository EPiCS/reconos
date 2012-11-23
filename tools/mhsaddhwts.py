#!/usr/bin/env python

import sys
import mhs as mhsmodule

DEFAULT_CLK = "clk_100_0000MHzMMCM0"
DEFAULT_RST = "sys_bus_reset"
DEFAULT_MEMFIFO_DEPTH = 128

FSL_VER="2.11.e"

if sys.argv[1] == "-nommu":
	use_mmu = False
else:
	use_mmu = True

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

def print_help():
	sys.stderr.write("Usage: mhsaddhwts.py [-nommu] <system.mhs> <hwt0_directory> <hwt1_directory> ...\n")
	sys.stderr.write("output: The new mhs-file with added ReconOS system and hardware threads.\n")

if len(sys.argv) < 3:
	print_help()
	sys.exit(1)

if sys.argv[1] == "-nommu":
	base_design = sys.argv[2]
	hwts = sys.argv[3:]
else:
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

# insert HWTs:
if len(hwts) < 1 or len(hwts) > 14:
	sys.stderr.write("ERROR: you must specify at least 1 and at most 14 hardware threads\n")
	sys.exit(1)
	
names = map(lambda x: x[:-8],hwts)
versions = map(lambda x: x[-7:].replace("_","."),hwts)
	
for i in range(len(hwts)):
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

for i in range(len(a_fifos)):
	mhs.addPCore(fifo32(a_fifos[i],"proc_control_0_reset%d" % i))

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


