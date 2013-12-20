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
#   description:  The ReconOS preprocessor to generate the pcores files.
# 
# ======================================================================

if [ $# -ne 3 ]
then
	echo "ERROR: You must specifiy exactly three arguments:"
	echo "         input file, number of HWTs, output file"
	exit
fi

if [ ! -f $1 ]
then
	echo "ERROR: Input file not found"
	exit
fi

python "$RECONOS/tools/python/preproc.py" $1 $2 > .~tmp
mv .~tmp $3

