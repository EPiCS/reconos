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
./basicmath_small_hybrid 2 0 > output_small_hybrid_2swt.txt 2>> small.log
./basicmath_small_hybrid 3 0 > output_small_hybrid_3swt.txt 2>> small.log
./basicmath_small_hybrid 4 0 > output_small_hybrid_4swt.txt 2>> small.log
./basicmath_small_hybrid 5 0 > output_small_hybrid_5swt.txt 2>> small.log
./basicmath_small_hybrid 6 0 > output_small_hybrid_6swt.txt 2>> small.log


#Hardwarethreads
./basicmath_small_hybrid 0 1 > output_small_hybrid_1hwt.txt 2>> small.log
./basicmath_small_hybrid 0 2 > output_small_hybrid_2hwt.txt 2>> small.log
./basicmath_small_hybrid 0 3 > output_small_hybrid_3hwt.txt 2>> small.log
./basicmath_small_hybrid 0 4 > output_small_hybrid_4hwt.txt 2>> small.log
./basicmath_small_hybrid 0 5 > output_small_hybrid_5hwt.txt 2>> small.log
./basicmath_small_hybrid 0 6 > output_small_hybrid_6hwt.txt 2>> small.log
./basicmath_small_hybrid 0 7 > output_small_hybrid_7hwt.txt 2>> small.log
./basicmath_small_hybrid 0 8 > output_small_hybrid_8hwt.txt 2>> small.log
./basicmath_small_hybrid 0 9 > output_small_hybrid_9hwt.txt 2>> small.log
./basicmath_small_hybrid 0 10 > output_small_hybrid_10hwt.txt 2>> small.log
./basicmath_small_hybrid 0 11 > output_small_hybrid_11hwt.txt 2>> small.log
./basicmath_small_hybrid 0 12 > output_small_hybrid_12hwt.txt 2>> small.log
#./basicmath_small_hybrid 0 13 > output_small_hybrid_13hwt.txt 2>> small.log
#./basicmath_small_hybrid 0 14 > output_small_hybrid_14hwt.txt 2>> small.log

#mixed
./basicmath_small_hybrid 1 1 > output_small_hybrid_1swt_1hwt.txt 2>> small.log
./basicmath_small_hybrid 1 2 > output_small_hybrid_1swt_2hwt.txt 2>> small.log
./basicmath_small_hybrid 1 3 > output_small_hybrid_1swt_3hwt.txt 2>> small.log
./basicmath_small_hybrid 2 1 > output_small_hybrid_2swt_1hwt.txt 2>> small.log
./basicmath_small_hybrid 2 2 > output_small_hybrid_2swt_2hwt.txt 2>> small.log
./basicmath_small_hybrid 2 3 > output_small_hybrid_2swt_3hwt.txt 2>> small.log
./basicmath_small_hybrid 3 1 > output_small_hybrid_3swt_1hwt.txt 2>> small.log
./basicmath_small_hybrid 3 2 > output_small_hybrid_3swt_2hwt.txt 2>> small.log
./basicmath_small_hybrid 3 3 > output_small_hybrid_3swt_3hwt.txt 2>> small.log

#LARGE
#NORMAL
./basicmath_large > output_large.txt 2> large.log

#HYBRID
./basicmath_large_hybrid > output_large_hybrid_normal.txt 2>> large.log

#Softwarethreads
./basicmath_large_hybrid 1 0 > output_large_hybrid_1swt.txt 2>> large.log
./basicmath_large_hybrid 2 0 > output_large_hybrid_2swt.txt 2>> large.log
./basicmath_large_hybrid 3 0 > output_large_hybrid_3swt.txt 2>> large.log
./basicmath_large_hybrid 4 0 > output_large_hybrid_4swt.txt 2>> large.log
./basicmath_large_hybrid 5 0 > output_large_hybrid_5swt.txt 2>> large.log
./basicmath_large_hybrid 6 0 > output_large_hybrid_6swt.txt 2>> large.log

#Hardwarethreads
./basicmath_large_hybrid 0 1 > output_large_hybrid_1hwt.txt 2>> large.log
./basicmath_large_hybrid 0 2 > output_large_hybrid_2hwt.txt 2>> large.log
./basicmath_large_hybrid 0 3 > output_large_hybrid_3hwt.txt 2>> large.log
./basicmath_large_hybrid 0 4 > output_large_hybrid_4hwt.txt 2>> large.log
./basicmath_large_hybrid 0 5 > output_large_hybrid_5hwt.txt 2>> large.log
./basicmath_large_hybrid 0 6 > output_large_hybrid_6hwt.txt 2>> large.log
./basicmath_large_hybrid 0 7 > output_large_hybrid_7hwt.txt 2>> large.log
./basicmath_large_hybrid 0 8 > output_large_hybrid_8hwt.txt 2>> large.log
./basicmath_large_hybrid 0 9 > output_large_hybrid_8hwt.txt 2>> large.log
./basicmath_large_hybrid 0 10 > output_large_hybrid_10hwt.txt 2>> large.log
./basicmath_large_hybrid 0 11 > output_large_hybrid_11hwt.txt 2>> large.log
./basicmath_large_hybrid 0 12 > output_large_hybrid_12hwt.txt 2>> large.log
#./basicmath_large_hybrid 0 13 > output_large_hybrid_13hwt.txt 2>> large.log
#./basicmath_large_hybrid 0 14 > output_large_hybrid_14hwt.txt 2>> large.log

#mixed
./basicmath_large_hybrid 1 1 > output_large_hybrid_1swt_1hwt.txt 2>> large.log
./basicmath_large_hybrid 1 2 > output_large_hybrid_1swt_2hwt.txt 2>> large.log
./basicmath_large_hybrid 1 3 > output_large_hybrid_1swt_3hwt.txt 2>> large.log
./basicmath_large_hybrid 2 1 > output_large_hybrid_2swt_1hwt.txt 2>> large.log
./basicmath_large_hybrid 2 2 > output_large_hybrid_2swt_2hwt.txt 2>> large.log
./basicmath_large_hybrid 2 3 > output_large_hybrid_2swt_3hwt.txt 2>> large.log
./basicmath_large_hybrid 3 1 > output_large_hybrid_3swt_1hwt.txt 2>> large.log
./basicmath_large_hybrid 3 2 > output_large_hybrid_3swt_2hwt.txt 2>> large.log
./basicmath_large_hybrid 3 3 > output_large_hybrid_3swt_3hwt.txt 2>> large.log
