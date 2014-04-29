#!/bin/sh

# runme_hybrid.sh
# 
# shell script to run various basicmath_hybrid configurations
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

rm output_*

#SMALL
#NORMAL
./basicmath_small > output_small.txt 2> small.log

#HYBRID
./basicmath_small_hybrid > output_small_hybrid_normal.txt 2>> small.log

#Softwarethreads
./basicmath_small_hybrid 1 0 > output_small_hybrid_1swt.txt 2>> small.log

#Hardwarethreads
./basicmath_small_hybrid 0 1 > output_small_hybrid_1hwt.txt 2>> small.log

#mixed
./basicmath_small_hybrid 1 1 > output_small_hybrid_1swt_1hwt.txt 2>> small.log
