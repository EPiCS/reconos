#!/bin/bash
BASE_DESIGN="ml605_linux_13.3"
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
cp -r $RECONOS/designs/$BASE_DESIGN edk

# link to ReconOS pcores
mkdir edk/pcores
ln -s $RECONOS/pcores/* edk/pcores

# add links to hardware threads
cd edk/pcores
for HWT in $HWTS
do
	ln -sf ../../$HWT .
done
cd -

# add ReconOS to the edk project
cp edk/system.mhs edk/system.mhs.orig
$RECONOS/tools/mhsaddhwts.py edk/system.mhs.orig $HWTS > edk/system.mhs


