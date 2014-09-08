#!/bin/bash

BASE_DESIGN="ml605_linux_13.3"
HWTS="sort_demo_parallelized_oav_v1_00_v\
      sort_demo_parallelized_oav_v1_00_v\
      sort_demo_parallelized_tav_v1_00_v\
      sort_demo_parallelized_tav_v1_00_v\
      sort_demo_parallelized_tmr_v1_00_v\
      sort_demo_parallelized_tmr_v1_00_v\
      sort_demo_parallelized_ctmr_v1_00_v\
      sort_demo_parallelized_ctmr_v1_00_v"

if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


EDKDIR="edk_linux_parallelized"

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


