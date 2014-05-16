#!/bin/bash

BASE_DESIGN="ml605_xilkernel_14.2"
HWTS="hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a\
      hwt_matrixmul_v2_00_a"


if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


EDKDIR="edk_xilkernel"

# copy base design
cp -r $RECONOS/designs/$BASE_DESIGN $EDKDIR

# link to ReconOS pcores
mkdir $EDKDIR/pcores
ln -s $RECONOS/pcores/* $EDKDIR/pcores

# add links to hardware threads
cd $EDKDIR/pcores
for HWT in $HWTS
do
	ln -sf ../../$HWT .
done
cd -

# add ReconOS to the edk project
cp $EDKDIR/system.mhs $EDKDIR/system.mhs.orig
$RECONOS/tools/mhsaddhwts.py -nommu $EDKDIR/system.mhs.orig $HWTS > $EDKDIR/system.mhs


