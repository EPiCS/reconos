#!/bin/bash
BASE_DESIGN="ml605_linux_14.2"
TARGET_DIR="edk_linux"
HWTS="hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a\
      hwt_short_term_synthesis_filtering_v0_01_a"

if [ -z "$RECONOS" ]
then
	echo "ERROR: RECONOS environment variable is not set. $RECONOS must point to the root of the ReconOS repository."
	exit 1
fi


# copy base design
cp -r $RECONOS/designs/$BASE_DESIGN $TARGET_DIR

# link to ReconOS pcores
mkdir $TARGET_DIR/pcores
ln -s $RECONOS/pcores/* $TARGET_DIR/pcores

# add links to hardware threads
cd $TARGET_DIR/pcores
for HWT in $HWTS
do
	ln -sf ../../$HWT .
done
cd -

# add ReconOS to the edk project
cp $TARGET_DIR/system.mhs $TARGET_DIR/system.mhs.orig
$RECONOS/tools/mhsaddhwts.py $TARGET_DIR/system.mhs.orig $HWTS > $TARGET_DIR/system.mhs

#TODO: fault channel still has to be wired up manually!
