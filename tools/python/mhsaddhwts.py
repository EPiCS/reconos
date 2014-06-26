#!/usr/bin/env python
# coding: utf8

#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Andreas Agne, University of Paderborn
#                 Markus Happe, University of Paderborn
#                 Christoph Rüthing, University of Paderborn
#   description:  Script to add the ReconOS cores and HWTs to an mhs.
# 
# ======================================================================

import sys
import mhstools

DEFAULT_MEMIF_FIFO_DEPTH = 128
DEFAULT_OSIF_FIFO_DEPTH = 32

OSIF_FIFO_BASE_ADDR = 0x75A00000
OSIF_FIFO_MEM_SIZE = 0x10000
OSIF_INTC_BASE_ADDR = 0x7B400000
OSIF_INTC_MEM_SIZE = 0x10000
PROC_CONTROL_BASE_ADDR = 0x6FE00000
PROC_CONTROL_MEM_SIZE = 0x10000

def hwt_reconf(name, num, version, use_mem):
	instance = mhstools.MHSPCore(name)
	instance.addEntry("PARAMETER", "INSTANCE", "hwt_reconf_%d" % (num - num_static_hwts))
	instance.addEntry("PARAMETER", "HW_VER", version)
	instance.addEntry("BUS_INTERFACE", "OSIF_FIFO_Sw2Hw", "reconos_osif_fifo_%d_sw2hw_FIFO_S" % num)
	instance.addEntry("BUS_INTERFACE", "OSIF_FIFO_Hw2Sw", "reconos_osif_fifo_%d_hw2sw_FIFO_M" % num)
	if use_mem:
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Hwt2Mem", "reconos_memif_fifo_%d_hwt2mem_FIFO_M" % num)
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Mem2Hwt", "reconos_memif_fifo_%d_mem2hwt_FIFO_S" % num)
	instance.addEntry("PORT", "HWT_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "HWT_Rst", "reconos_proc_control_0_PROC_Hwt_Rst_%d" % num)
	instance.addEntry("PORT", "HWT_Signal", "reconos_proc_control_0_PROC_Hwt_Signal_%d" % num)
	return instance

def hwt_static(name, num, version, use_mem):
	instance = mhstools.MHSPCore(name)
	instance.addEntry("PARAMETER", "INSTANCE", "hwt_static_%d" % num)
	instance.addEntry("PARAMETER", "HW_VER", version)
	instance.addEntry("BUS_INTERFACE", "OSIF_FIFO_Sw2Hw", "reconos_osif_fifo_%d_sw2hw_FIFO_S" % num)
	instance.addEntry("BUS_INTERFACE", "OSIF_FIFO_Hw2Sw", "reconos_osif_fifo_%d_hw2sw_FIFO_M" % num)
	if use_mem:
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Hwt2Mem", "reconos_memif_fifo_%d_hwt2mem_FIFO_M" % num)
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Mem2Hwt", "reconos_memif_fifo_%d_mem2hwt_FIFO_S" % num)
	instance.addEntry("PORT", "HWT_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "HWT_Rst", "reconos_proc_control_0_PROC_Hwt_Rst_%d" % num)
	instance.addEntry("PORT", "HWT_Signal", "reconos_proc_control_0_PROC_Hwt_Signal_%d" % num)
	return instance

def osif_fifo(num, direction):
	instance = mhstools.MHSPCore("reconos_fifo")
        instance.addEntry("PARAMETER", "INSTANCE", "reconos_osif_fifo_%d_" % num + direction)
        instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
        instance.addEntry("PARAMETER", "C_FIFO_DEPTH", DEFAULT_OSIF_FIFO_DEPTH)
        instance.addEntry("BUS_INTERFACE", "FIFO_M", "reconos_osif_fifo_%d_" % num + direction + "_FIFO_M")
        instance.addEntry("BUS_INTERFACE", "FIFO_S", "reconos_osif_fifo_%d_" % num + direction + "_FIFO_S")
	if direction == "hw2sw":
		instance.addEntry("PORT", "FIFO_Has_Data", "reconos_osif_fifo_%d_" % num + direction + "_FIFO_Has_Data")
	instance.addEntry("PORT", "FIFO_Rst", "reconos_proc_control_0_PROC_Hwt_Rst_%d" % num)
	instance.addEntry("PORT", "FIFO_S_Clk", DEFAULT_CLK)
	return instance



# HW_VER, C_FIFO_WIDTH, OSIF_FIFO_BASE_ADDR, OSIF_FIFO_MEM_SIZE
def osif(num_hwts):
	instance = mhstools.MHSPCore("reconos_osif")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_osif_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_BASEADDR", "0x%x" % OSIF_FIFO_BASE_ADDR)
	instance.addEntry("PARAMETER", "C_HIGHADDR", "0x%x" % (OSIF_FIFO_BASE_ADDR + OSIF_FIFO_MEM_SIZE - 1))
	instance.addEntry("PARAMETER", "C_NUM_FIFOS", num_hwts)
	instance.addEntry("PARAMETER", "C_FIFO_WIDTH", "32")
	for i in range(num_hwts):
		instance.addEntry("BUS_INTERFACE", "FIFO_S_%d" % i, "reconos_osif_fifo_%d_hw2sw_FIFO_S" % i)
		instance.addEntry("BUS_INTERFACE", "FIFO_M_%d" % i, "reconos_osif_fifo_%d_sw2hw_FIFO_M" % i)
	instance.addEntry("BUS_INTERFACE", "S_AXI", HWT_BUS)
	instance.addEntry("PORT", "S_AXI_ACLK", DEFAULT_CLK)
	return instance

# HW_VER, OSIF_INTC_BASE_ADDR, OSIF_INCT_MEM_SIZE
def osif_intc(num_hwts):
	instance = mhstools.MHSPCore("reconos_osif_intc")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_osif_intc_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_BASEADDR", "0x%x" % OSIF_INTC_BASE_ADDR)
	instance.addEntry("PARAMETER", "C_HIGHADDR", "0x%x" % (OSIF_INTC_BASE_ADDR + OSIF_INTC_MEM_SIZE - 1))
	instance.addEntry("PARAMETER", "C_NUM_INTERRUPTS", num_hwts)
	instance.addEntry("BUS_INTERFACE", "S_AXI", HWT_BUS)
	instance.addEntry("PORT", "S_AXI_ACLK", DEFAULT_CLK)
	instance.addEntry("PORT", "OSIF_INTC_Out", "reconos_osif_intc_0_OSIF_INTC_Out")
	for i in range(num_hwts):
		instance.addEntry("PORT", "OSIF_INTC_In_%d" % i, "reconos_osif_fifo_%d_hw2sw_FIFO_Has_Data" % i)
	instance.addEntry("PORT", "OSIF_INTC_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	return instance

# C_FIFO_DEPTH
def memif_fifo(num, direction):
	instance = mhstools.MHSPCore("reconos_fifo")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_memif_fifo_%d_" % num + direction)
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_FIFO_DEPTH", DEFAULT_MEMIF_FIFO_DEPTH)
	instance.addEntry("BUS_INTERFACE", "FIFO_M", "reconos_memif_fifo_%d_" % num + direction + "_FIFO_M")
	instance.addEntry("BUS_INTERFACE", "FIFO_S", "reconos_memif_fifo_%d_" % num + direction + "_FIFO_S")
	instance.addEntry("PORT", "FIFO_Rst", "reconos_proc_control_0_PROC_Hwt_Rst_%d" % num)
	instance.addEntry("PORT", "FIFO_S_Clk", DEFAULT_CLK)
	return instance

# HW_VER, PROC_CONTROL_BASE_ADDR, PROC_CONTROL_MEM_SIZE
def proc_control(num_hwts, use_mmu):
	instance = mhstools.MHSPCore("reconos_proc_control")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_proc_control_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_BASEADDR", "0x%x" % PROC_CONTROL_BASE_ADDR)
	instance.addEntry("PARAMETER", "C_HIGHADDR", "0x%x" % (PROC_CONTROL_BASE_ADDR + PROC_CONTROL_MEM_SIZE - 1))
	instance.addEntry("PARAMETER", "C_NUM_HWTS", num_hwts)
	instance.addEntry("BUS_INTERFACE", "S_AXI", HWT_BUS)
	instance.addEntry("PORT", "S_AXI_ACLK", DEFAULT_CLK)
	instance.addEntry("PORT", "PROC_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "PROC_Rst", DEFAULT_RST)
	for i in range(num_hwts):
		instance.addEntry("PORT", "PROC_Hwt_Rst_%d" % i, "reconos_proc_control_0_PROC_Hwt_Rst_%d" % i)
		instance.addEntry("PORT", "PROC_Hwt_Signal_%d" % i, "reconos_proc_control_0_PROC_Hwt_Signal_%d" % i)
	instance.addEntry("PORT", "PROC_Sys_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	if use_mmu:
		instance.addEntry("PORT", "PROC_Pgf_Int", "reconos_proc_control_0_PROC_Pgf_Int")
		instance.addEntry("PORT", "MMU_Pgf", "reconos_memif_mmu_0_MMU_Pgf")
		instance.addEntry("PORT", "MMU_Fault_Addr", "reconos_memif_mmu_0_MMU_Fault_Addr")
		instance.addEntry("PORT", "MMU_Retry", "reconos_proc_control_0_MMU_Retry")
		instance.addEntry("PORT", "MMU_Pgd", "reconos_proc_control_0_MMU_Pgd")
		instance.addEntry("PORT", "MMU_Tlb_Hits", "reconos_memif_mmu_0_MMU_Tlb_Hits")
		instance.addEntry("PORT", "MMU_Tlb_Misses", "reconos_memif_mmu_0_MMU_Tlb_Misses")
	return instance

# HW_VER
def arbiter(num_hwts):
	instance = mhstools.MHSPCore("reconos_memif_arbiter")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_memif_arbiter_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_NUM_HWTS", num_hwts)
	for i in range(num_hwts):
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_In_Hwt2Mem_%d" % i, "reconos_memif_fifo_%d_hwt2mem_FIFO_S" % i)
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_In_Mem2Hwt_%d" % i, "reconos_memif_fifo_%d_mem2hwt_FIFO_M" % i)
	instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Out_Mem2Hwt", "reconos_memif_arbiter_0_MEMIF_FIFO_Out_Mem2Hwt")
	instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Out_Hwt2Mem", "reconos_memif_arbiter_0_MEMIF_FIFO_Out_Hwt2Mem")
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Out", "reconos_memif_arbiter_0_CTRL_FIFO_Out")
	instance.addEntry("PORT", "TCTRL_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "TCTRL_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	return instance

# HW_VER, C_PAGE_SIZE, C_MAX_BURST_SIZE
def burst_converter():
	instance = mhstools.MHSPCore("reconos_memif_burst_converter")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_memif_burst_converter_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_PAGE_SIZE", 4096)
	instance.addEntry("PARAMETER", "C_MAX_BURST_SIZE", 256)
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_In", "reconos_memif_arbiter_0_CTRL_FIFO_Out")
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Out", "reconos_memif_burst_converter_0_CTRL_FIFO_Out")
	instance.addEntry("PORT", "BCONV_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "BCONV_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	return instance

# HW_VER, C_TLB_SIZE
def mmu(arch):
	instance = mhstools.MHSPCore("reconos_memif_mmu_" + arch)
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_memif_mmu_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	instance.addEntry("PARAMETER", "C_TLB_SIZE", 16)
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_In", "reconos_memif_burst_converter_0_CTRL_FIFO_Out")
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Out", "reconos_memif_mmu_0_CTRL_FIFO_Out")
	instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Mmu", "reconos_memif_mmu_0_CTRL_FIFO_Mmu")
	instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Mmu", "reconos_memif_memory_controller_0_MEMIF_FIFO_Mmu")
	instance.addEntry("PORT", "MMU_Pgf", "reconos_memif_mmu_0_MMU_Pgf")
	instance.addEntry("PORT", "MMU_Fault_Addr", "reconos_memif_mmu_0_MMU_Fault_Addr")
	instance.addEntry("PORT", "MMU_Retry", "reconos_proc_control_0_MMU_Retry")
	instance.addEntry("PORT", "MMU_Pgd", "reconos_proc_control_0_MMU_Pgd")
	instance.addEntry("PORT", "MMU_Tlb_Hits", "reconos_memif_mmu_0_MMU_Tlb_Hits")
	instance.addEntry("PORT", "MMU_Tlb_Misses", "reconos_memif_mmu_0_MMU_Tlb_Misses")
	instance.addEntry("PORT", "MMU_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "MMU_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	return instance

# HW_VER
def memory_controller(use_mmu):
	instance = mhstools.MHSPCore("reconos_memif_memory_controller")
	instance.addEntry("PARAMETER", "INSTANCE", "reconos_memif_memory_controller_0")
	instance.addEntry("PARAMETER", "HW_VER", "1.00.a")
	if use_mmu:
		instance.addEntry("PARAMETER", "C_USE_MMU_PORT", "TRUE")
		instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Mmu", "reconos_memif_mmu_0_CTRL_FIFO_Mmu")
		instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Mmu", "reconos_memif_memory_controller_0_MEMIF_FIFO_Mmu")
		instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Hwt", "reconos_memif_mmu_0_CTRL_FIFO_Out")
	else:
		instance.addEntry("PARAMETER", "C_USE_MMU_PORT", "FALSE")
		instance.addEntry("BUS_INTERFACE", "CTRL_FIFO_Hwt", "reconos_memif_burst_converter_0_CTRL_FIFO_Out")
	instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Mem2Hwt", "reconos_memif_arbiter_0_MEMIF_FIFO_Out_Mem2Hwt")
	instance.addEntry("BUS_INTERFACE", "MEMIF_FIFO_Hwt2Mem", "reconos_memif_arbiter_0_MEMIF_FIFO_Out_Hwt2Mem")
	instance.addEntry("BUS_INTERFACE", "M_AXI", MEMORY_BUS)
	instance.addEntry("PORT", "M_AXI_ACLK", DEFAULT_CLK)
	instance.addEntry("PORT", "MEMCTRL_Clk", DEFAULT_CLK)
	instance.addEntry("PORT", "MEMCTRL_Rst", "reconos_proc_control_0_PROC_Sys_Rst")
	return instance


def print_help():
	sys.stderr.write("Usage: mhsaddhwts.py [-nommu] [-reconf] [-nomem] <architecture> <system.mhs> <num_static_hwts> <num_reconf_regions> <hwt0_directory>[#<count>] <hwt1_directory>[#<count>] ...\n")
	sys.stderr.write("Output: new mhs-file with added ReconOS system and hardware threads.\n")


class HWT:
	"""
This class represents a HWT
fields: self.name
        self.version
        self.count
        self.is_reconf
        self.slots
"""
	def __init__(self, hwt_str, is_reconf):
		self.name = ""
		self.version = ""
		self.count = 0
		self.is_reconf = is_reconf
		self.slots = []
		self.parse(hwt_str)

		if not self.is_reconf and self.count == 0:
			self.count = 1

	def parse(self, hwt_str):
		STATE_NAME = 0
		STATE_STATIC_OPTION = 1
		STATE_RECONF_OPTION = 2

		state = STATE_NAME

		for i in range(len(hwt_str)):
			last = (i == len(hwt_str) - 1)

			if state == STATE_NAME:
				if hwt_str[i] == '#':
					self.name = hwt_str[:i - 8]
					self.version = hwt_str[i - 6:i].replace("_", ".")

					if self.is_reconf:
						start = i + 1
						state = STATE_RECONF_OPTION
					else:
						state = STATE_STATIC_OPTION

				elif last:
					self.name = hwt_str[:i - 7]
					self.version = hwt_str[i - 5:].replace("_", ".")

			elif state == STATE_STATIC_OPTION:
				self.count = int(hwt_str[i:])
				break

			elif state == STATE_RECONF_OPTION:
				if hwt_str[i] == ',':
					self.slots.append(int(hwt_str[start:i]))
					self.count += 1
					start = i + 1
				elif last:
					self.slots.append(int(hwt_str[start:]))
					self.count += 1

        def __str__(self):
                return "HWT: " + self.name + ", Version: " + self.version + ", Count: " + str(self.count) + ", Reconfigurable: " + str(self.is_reconf)


# at first parse all parameters
if len(sys.argv) < 6:
	print_help()
	sys.exit(1)

arg_pos = 1

if sys.argv[arg_pos] == "-nommu":
	use_mmu = False
	arg_pos += 1
else:
	use_mmu = True

if sys.argv[arg_pos] == "-reconf":
	use_reconf = True
	arg_pos += 1
else:
	use_reconf = False

if sys.argv[arg_pos] == "-nomem":
	use_mem = False
	use_mmu = False
	arg_pos += 1
else:
	use_mem = True

arch = sys.argv[arg_pos]
mhs = mhstools.MHS(sys.argv[arg_pos + 1])
num_static_hwts = int(sys.argv[arg_pos + 2])
num_reconf_regions = int(sys.argv[arg_pos + 3])
hwts_str = sys.argv[arg_pos + 4:]


if arch == "zynq":
	HWT_BUS = "axi_hwt"
	MEMORY_BUS = "axi_acp"

	DEFAULT_CLK = "processing_system7_0_FCLK_CLK0"
	DEFAULT_RST = "processing_system7_0_FCLK_RESET0_N_0"
	DEFAULT_RST_POLARITY = 0 # 0 for egative, 1 for positive
elif arch == "microblaze":
	HWT_BUS = "axi_sys"
	MEMORY_BUS = "axi_mem"

	DEFAULT_CLK = "clk_100_0000MHzMMCM0"
	DEFAULT_RST = "proc_sys_reset_0_Peripheral_aresetn"
	DEFAULT_RST_POLARITY = 0 # 0 for egative, 1 for positive
else:
	sys.stderr.write("ERROR: Architecture not supported\n")
	sys.exit(1)


# insert reconos system

if num_static_hwts < 1 and num_reconf_regions < 1:
	sys.stderr.write("ERROR: you must specify at least 1 hardware thread\n")
	sys.exit(1)

num_hwts = num_static_hwts + num_reconf_regions


# parse HWT string
hwts = []
for i in range(len(hwts_str)):
	if use_reconf and i == len(hwts_str) - 1:
		hwts.append(HWT(hwts_str[i], True))
	else:
		hwts.append(HWT(hwts_str[i], False))


# insert HWTs
count = 0

for i in range(len(hwts)):
	if not hwts[i].is_reconf:
		for j in range(hwts[i].count):
			mhs.addPCore(hwt_static(hwts[i].name, count, hwts[i].version, use_mem))
			mhs.addPCore(osif_fifo(count, "sw2hw"))
			mhs.addPCore(osif_fifo(count, "hw2sw"))
			if use_mem:
				mhs.addPCore(memif_fifo(count, "hwt2mem"))
				mhs.addPCore(memif_fifo(count, "mem2hwt"))
			count += 1


for j in range(num_reconf_regions):
	for i in range(len(hwts)):
		if hwts[i].is_reconf:
			if hwts[i].slots.count(j) == 0 and hwts[i].count != 0:
				mhs.addPCore(hwt_reconf("reconos_hwt_idle", count, "1.00.a", use_mem))
			else:
				mhs.addPCore(hwt_reconf(hwts[i].name, count, hwts[i].version, use_mem))

			mhs.addPCore(osif_fifo(count, "sw2hw"))
			mhs.addPCore(osif_fifo(count, "hw2sw"))
			mhs.addPCore(memif_fifo(count, "hwt2mem"))
			mhs.addPCore(memif_fifo(count, "mem2hwt"))
			
			count += 1

# add osif
mhs.addPCore(osif(num_hwts))
mhs.addPCore(osif_intc(num_hwts))

# insert proc control
mhs.addPCore(proc_control(num_hwts, use_mmu))

# add memory subsystem
if use_mem:
	mhs.addPCore(arbiter(num_hwts))
	mhs.addPCore(burst_converter())
	if use_mmu:
		mhs.addPCore(mmu(arch))
	mhs.addPCore(memory_controller(use_mmu))


if arch == "zynq":
	ps7 = mhs.getPCore("processing_system7_0")
	if ps7 is None:
		sys.stderr.write("ERROR: no processing system found\n")
		sys.exit(1)

	if use_mem:
		ps7.addEntry("PORT", "IRQ_F2P", "reconos_proc_control_0_PROC_Pgf_Int & reconos_osif_intc_0_OSIF_INTC_Out")

		ps7.addEntry("BUS_INTERFACE", "S_AXI_ACP", "axi_acp")
		ps7.addEntry("PARAMETER", "C_INTERCONNECT_S_AXI_ACP_MASTERS", "reconos_memif_memory_controller_0.M_AXI")
	else:
		ps7.addEntry("PORT", "IRQ_F2P", "reconos_osif_intc_0_OSIF_INTC_Out")

elif arch == "microblaze":
	intc = mhs.getPCore("microblaze_0_intc")
	if intc is None:
		sys.stderr.write("ERROR: no interupt controller found\n")
		sys.exit(1)

	intr = intc.getValue("INTR")
	if use_mmu:
		intr = "reconos_proc_control_0_PROC_Pgf_Int & reconos_osif_intc_0_OSIF_INTC_Out & " + intr
	else:
		intr = "reconos_osif_intc_0_OSIF_INTC_Out & " + intr
	intc.setValue("INTR", intr)

	memctrl = mhs.getPCore("DDR3_SDRAM")
	if intc is None:
		sys.stderr.write("ERROR: no memory controller found\n")
		sys.exit(1)

	memslv = memctrl.getValue("C_INTERCONNECT_S_AXI_MASTERS")
	memslv = "reconos_memif_memory_controller_0.M_AXI & " + memslv
	memctrl.setValue("C_INTERCONNECT_S_AXI_MASTERS", memslv)


sys.stdout.write(str(mhs))

