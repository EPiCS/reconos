#!/bin/sh

# runme_times.sh
# 
# shell script to run various basicmath_hybrid configurations
# similar to runme_hybrid but using the function time for additional
# run time information
# 
# Author:	Alexander Sprenger <alsp@mail.upb.de> Universitaet Paderborn
# 
# History:	08.03.2013 Alexander Sprenger created

#SMALL
#NORMAL
(time -v ./basicmath_small) > /demos/mibench/basicmath/outputs_noprintf/output_small.txt 2>&1

#HYBRID
(time -v ./basicmath_small_hybrid) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_normal.txt 2>&1

#Softwarethreads
(time -v ./basicmath_small_hybrid 1 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_1swt.txt 2>&1
(time -v ./basicmath_small_hybrid 2 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_2swt.txt 2>&1
(time -v ./basicmath_small_hybrid 3 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_3swt.txt 2>&1
(time -v ./basicmath_small_hybrid 4 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_4swt.txt 2>&1
(time -v ./basicmath_small_hybrid 5 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_5swt.txt 2>&1
(time -v ./basicmath_small_hybrid 6 0) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_6swt.txt 2>&1


#Hardwarethreads
(time -v ./basicmath_small_hybrid 0 1) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_1hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 0 2) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_2hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 0 3) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_3hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 0 4) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_4hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 0 5) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_5hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 0 6) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_6hwt.txt 2>&1

#mixed
(time -v ./basicmath_small_hybrid 1 1) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_1swt_1hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 1 2) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_1swt_2hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 1 3) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_1swt_3hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 2 1) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_2swt_1hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 2 2) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_2swt_2hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 2 3) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_2swt_3hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 3 1) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_3swt_1hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 3 2) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_3swt_2hwt.txt 2>&1
(time -v ./basicmath_small_hybrid 3 3) > /demos/mibench/basicmath/outputs_noprintf/output_small_hybrid_3swt_3hwt.txt 2>&1

#LARGE
#NORMAL
(time -v ./basicmath_large) > /demos/mibench/basicmath/outputs_noprintf/output_large.txt 2>&1

#HYBRID
(time -v ./basicmath_large_hybrid) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_normal.txt 2>&1

#Softwarethreads
(time -v ./basicmath_large_hybrid 1 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_1swt.txt 2>&1
(time -v ./basicmath_large_hybrid 2 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_2swt.txt 2>&1
(time -v ./basicmath_large_hybrid 3 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_3swt.txt 2>&1
(time -v ./basicmath_large_hybrid 4 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_4swt.txt 2>&1
(time -v ./basicmath_large_hybrid 5 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_5swt.txt 2>&1
(time -v ./basicmath_large_hybrid 6 0) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_6swt.txt 2>&1


#Hardwarethreads
(time -v ./basicmath_large_hybrid 0 1) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_1hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 0 2) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_2hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 0 3) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_3hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 0 4) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_4hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 0 5) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_5hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 0 6) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_6hwt.txt 2>&1

#mixed
(time -v ./basicmath_large_hybrid 1 1) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_1swt_1hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 1 2) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_1swt_2hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 1 3) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_1swt_3hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 2 1) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_2swt_1hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 2 2) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_2swt_2hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 2 3) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_2swt_3hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 3 1) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_3swt_1hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 3 2) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_3swt_2hwt.txt 2>&1
(time -v ./basicmath_large_hybrid 3 3) > /demos/mibench/basicmath/outputs_noprintf/output_large_hybrid_3swt_3hwt.txt 2>&1
