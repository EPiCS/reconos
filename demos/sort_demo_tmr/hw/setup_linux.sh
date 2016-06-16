#!/bin/bash

BASE_DESIGN="ml605_linux_13.3"
HWTS="hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n\
      hwt_sort_demo_v1_00_n"


if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


EDKDIR="edk_linux"

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
$RECONOS/tools/mhsaddhwts.py $EDKDIR/system.mhs.orig $HWTS > $EDKDIR/system.mhs


