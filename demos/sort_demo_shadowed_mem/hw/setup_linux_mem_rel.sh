#!/bin/bash

BASE_DESIGN="ml605_linux_14.2"
HWTS="hwt_sort_demo_v1_00_c\
      hwt_sort_demo_v1_00_c"


if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


EDKDIR="edk_mem_rel"

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


# HACK! Change non shadowing arbiter to shadowing arbiter in reliability mode
sed -i -e 's/BEGIN fifo32_arbiter/BEGIN fifo32_arbiter_sh_rel/' $EDKDIR/system.mhs


#TODO: fault channel still has to be wired up manually!
