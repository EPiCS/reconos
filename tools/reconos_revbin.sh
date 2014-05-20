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
#   description:  This script simply reverses the byte order of a file.
# 
# ======================================================================

if [ ! -f $1 ]
then
	echo "ERROR: Input file not found"
	exit
fi

python "$RECONOS/tools/python/reverse_byte_order.py" $1 > $2

