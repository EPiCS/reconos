#!/bin/bash
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
#   description:  The download script can be used to program the FPGA
#                 with a bitstream.
# 
# ======================================================================

if [ "$RECONOS_ARCH" = "zynq" ]
then
	if [ $# -ne 1 -a $# -ne 2 ]
	then
		echo "ERROR: No bitstream and ps7_init.tcl specified"
		exit
	fi

	if [ $# -eq 1 ]
	then
		echo -e "fpga -f $1\n" | xmd
	else
		echo -e "connect arm hw\nrst\nsource $2\nps7_init\ninit_user\nfpga -f $1\n" | xmd
	fi
	
elif [ "$RECONOS_ARCH" = "microblaze" ]
then
	echo -e "fpga -f $1\n" | xmd

else
	echo "ERROR: Unknown RECONOS_ARCH"
fi



