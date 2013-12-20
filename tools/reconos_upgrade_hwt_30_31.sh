#!/bin/sh
#
#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Christoph Rüthing, University of Paderborn
#   description:  Script to upgrade a hardware thread written for
#                 version 3.0 to version 3.1
# 
# ======================================================================

MPD='/home/christoph/Documents/reconos/demos/sort_demo/hw/hwt_sort_demo_v1_00_c/data/hwt_sort_demo_v2_1_0.mpd'
PAO='/home/christoph/Documents/reconos/demos/sort_demo/hw/hwt_sort_demo_v1_00_c/data/hwt_sort_demo_v2_1_0.pao'
VHDL='/home/christoph/Documents/reconos/demos/sort_demo/hw/hwt_sort_demo_v1_00_c/hdl/vhdl/hwt_sort_demo.vhd'

### Upgrade MPD

cp $MPD $MPD.bak

# remove all ReconOS v3.0 ports an busses
sed -i '
/^\s*BUS_INTERFACE\s*BUS\s*=\s*OS_SFSL.*/d
/^\s*BUS_INTERFACE\s*BUS\s*=\s*OS_MFSL.*/d
/^\s*BUS_INTERFACE\s*BUS\s*=\s*SFIFO32.*/d
/^\s*BUS_INTERFACE\s*BUS\s*=\s*MFIFO32.*/d

/^\s*PORT\s*OSFSL_Clk.*/d
/^\s*PORT\s*OSFSL_Rst.*/d

/^\s*PORT\s*OSFSL_S_Clk.*/d
/^\s*PORT\s*OSFSL_S_Read.*/d
/^\s*PORT\s*OSFSL_S_Data.*/d
/^\s*PORT\s*OSFSL_S_Control.*/d
/^\s*PORT\s*OSFSL_S_Exists.*/d

/^\s*PORT\s*OSFSL_M_Clk.*/d
/^\s*PORT\s*OSFSL_M_Write.*/d
/^\s*PORT\s*OSFSL_M_Data.*/d
/^\s*PORT\s*OSFSL_M_Control.*/d
/^\s*PORT\s*OSFSL_M_Full.*/d

/^\s*PORT\s*FIFO32_S_Clk.*/d
/^\s*PORT\s*FIFO32_S_Data.*/d
/^\s*PORT\s*FIFO32_S_Rd.*/d
/^\s*PORT\s*FIFO32_S_Fill.*/d

/^\s*PORT\s*FIFO32_M_Clk.*/d
/^\s*PORT\s*FIFO32_M_Data.*/d
/^\s*PORT\s*FIFO32_M_Wr.*/d
/^\s*PORT\s*FIFO32_M_Rem.*/d

/^\s*PORT\s*Rst.*/d
/^\s*PORT\s*Clk.*/d

/^END/d
' $MPD

# Insert ReconOS v3.1 ports and busses
cat >> $MPD.tmp << EOF
## ReconOS Ports UPGRADE

## Bus Interfaces
BUS_INTERFACE BUS=OSIF_FIFO_Sw2Hw, BUS_STD=S_FIFO, BUS_TYPE=INITIATOR
BUS_INTERFACE BUS=OSIF_FIFO_Hw2Sw, BUS_STD=M_FIFO, BUS_TYPE=INITIATOR
BUS_INTERFACE BUS=MEMIF_FIFO_Hwt2Mem, BUS_STD=M_FIFO, BUS_TYPE=INITIATOR
BUS_INTERFACE BUS=MEMIF_FIFO_Mem2Hwt, BUS_STD=S_FIFO, BUS_TYPE=INITIATOR

## Peripheral ports
PORT OSIF_FIFO_Sw2Hw_Data = "S_FIFO_Data", DIR = I, VEC = [31:0], BUS = OSIF_FIFO_Sw2Hw
PORT OSIF_FIFO_Sw2Hw_Fill = "S_FIFO_Fill", DIR = I, VEC = [15:0], BUS = OSIF_FIFO_Sw2Hw
PORT OSIF_FIFO_Sw2Hw_Empty = "S_FIFO_Empty", DIR = I, BUS = OSIF_FIFO_Sw2Hw
PORT OSIF_FIFO_Sw2Hw_RE = "S_FIFO_RE", DIR = O, BUS = OSIF_FIFO_Sw2Hw

PORT OSIF_FIFO_Hw2Sw_Data = "M_FIFO_Data", DIR = O, VEC = [31:0], BUS = OSIF_FIFO_Hw2Sw
PORT OSIF_FIFO_Hw2Sw_Rem = "M_FIFO_Rem", DIR = I, VEC = [15:0], BUS = OSIF_FIFO_Hw2Sw
PORT OSIF_FIFO_Hw2Sw_Full = "M_FIFO_Full", DIR = I, BUS = OSIF_FIFO_Hw2Sw
PORT OSIF_FIFO_Hw2Sw_WE = "M_FIFO_WE", DIR = O, BUS = OSIF_FIFO_Hw2Sw

PORT MEMIF_FIFO_Hwt2Mem_Data = "M_FIFO_Data", DIR = O, VEC = [31:0], BUS = MEMIF_FIFO_Hwt2Mem
PORT MEMIF_FIFO_Hwt2Mem_Rem = "M_FIFO_Rem", DIR = I, VEC = [15:0], BUS = MEMIF_FIFO_Hwt2Mem
PORT MEMIF_FIFO_Hwt2Mem_Full = "M_FIFO_Full", DIR = I, BUS = MEMIF_FIFO_Hwt2Mem
PORT MEMIF_FIFO_Hwt2Mem_WE = "M_FIFO_WE", DIR = O, BUS = MEMIF_FIFO_Hwt2Mem

PORT MEMIF_FIFO_Mem2Hwt_Data = "S_FIFO_Data", DIR = I, VEC = [31:0], BUS = MEMIF_FIFO_Mem2Hwt
PORT MEMIF_FIFO_Mem2Hwt_Fill = "S_FIFO_Fill", DIR = I, VEC = [15:0], BUS = MEMIF_FIFO_Mem2Hwt
PORT MEMIF_FIFO_Mem2Hwt_Empty = "S_FIFO_Empty", DIR = I, BUS = MEMIF_FIFO_Mem2Hwt
PORT MEMIF_FIFO_Mem2Hwt_RE = "S_FIFO_RE", DIR = O, BUS = MEMIF_FIFO_Mem2Hwt

PORT HWT_Clk = "", DIR = I, SIGIS = Clk
PORT HWT_Rst = "", DIR = I, SIGIS = Rst

END
EOF


### Upgrade PAO

cp $PAO $PAO.bak

sed -i '
  s/reconos_v3_00_[ab]/reconos_v3_00_c/g
' $PAO


### Upgrade VHDL

cp $VHDL $VHDL.bak

sed -in '
  1h
  1!H
  $ {
    g
    s/fsl_setup([^)]*);/osif_setup(\
		i_osif,\
		o_osif,\
		OSIF_FIFO_Sw2Hw_Data,\
		OSIF_FIFO_Sw2Hw_Fill,\
		OSIF_FIFO_Sw2Hw_Empty,\
		OSIF_FIFO_Hw2Sw_Rem,\
		OSIF_FIFO_Hw2Sw_Full,\
		OSIF_FIFO_Sw2Hw_RE,\
		OSIF_FIFO_Hw2Sw_Data,\
		OSIF_FIFO_Hw2Sw_WE\
	);/g

    s/memif_setup([^)]*);/memif_setup\
		i_memif,\
		o_memif,\
		MEMIF_FIFO_Mem2Hwt_Data,\
		MEMIF_FIFO_Mem2Hwt_Fill,\
		MEMIF_FIFO_Mem2Hwt_Empty,\
		MEMIF_FIFO_Hwt2Mem_Rem,\
		MEMIF_FIFO_Hwt2Mem_Full,\
		MEMIF_FIFO_Mem2Hwt_RE,\
		MEMIF_FIFO_Hwt2Mem_Data,\
		MEMIF_FIFO_Hwt2Mem_WE\
	);/g
    p
  }
' $VHDL

sed '
  s/reconos_v3_00_[ab]/reconos_v3_00_c/g

  0,/OSFSL_Clk\s*:\s*in.*/{//d;}
' $VHDL

#  /OSFSL_Clk\s*:\s*in.*/d
#  /OSFSL_Rst\s*:\s*in.*/d
#  /OSFSL_S_Clk\s*:\s*out.*/d
#  /OSFSL_S_Read\s*:\s*out.*/d
#  /OSFSL_S_Data\s*:\s*in.*/d
#  /OSFSL_S_Control\s*:\s*in.*/d
#  /OSFSL_S_Exists\s*:\s*in.*/d
#
#  /OSFSL_M_Clk\s*:\s*out.*/d
#  /OSFSL_M_Write\s*:\s*out.*/d
#  /OSFSL_M_Data\s*:\s*out.*/d
#  /OSFSL_M_Control\s*:\s*out.*/d
#  /OSFSL_M_Full\s*:\s*in.*/d
#
#  /FIFO32_S_Data\s*:\s*in.*/d
#  /FIFO32_S_Fill\s*:\s*in.*/d
#  /FIFO32_S_Rd\s*:\s*out.*/d
#
#  /FIFO32_M_Data\s*:\s*out.*/d
#  /FIFO32_M_Rem\s*:\s*in.*/d
#  /FIFO32_M_Wr\s*:\s*out.*/d
#
#  /clk\s*:\s*in.*/d
#  /rst\s*:\s*in.*/d
#
