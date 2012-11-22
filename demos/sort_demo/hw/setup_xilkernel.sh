#!/bin/bash

BASE_DESIGN="ml605_xilkernel_14.2"
HWTS="hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c"


if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


# copy base design
cp -r $RECONOS/designs/$BASE_DESIGN edk_nommu

# link to ReconOS pcores
mkdir edk_nommu/pcores
ln -s $RECONOS/pcores/* edk_nommu/pcores

# add links to hardware threads
cd edk_nommu/pcores
for HWT in $HWTS
do
	ln -sf ../../$HWT .
done
cd -

# add ReconOS to the edk project
cp edk_nommu/system.mhs edk_nommu/system.mhs.orig
$RECONOS/tools/mhsaddhwts.py -nommu edk_nommu/system.mhs.orig $HWTS > edk_nommu/system.mhs


