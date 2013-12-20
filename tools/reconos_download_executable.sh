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
#   description:  The download script can be used to download an
#                 executable to the main memory and execute it.
# 
# ======================================================================

if [ $# -ne 1 ]
then
	echo "ERROR: No executable specified"
	exit
fi

if [ "$RECONOS_ARCH" = "zynq" ]
then
	echo -e "connect arm hw\ndow $1\nrun\n" | xmd

elif [ "$RECONOS_ARCH" = "microblaze" ]
then
	echo -e "connect mb mdm\nrst\ndow $1\nrun\n" | xmd

else
	echo "ERROR: Unknown RECONOS_ARCH"
fi

