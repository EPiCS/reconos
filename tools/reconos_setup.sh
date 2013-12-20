#!/bin/sh
#
#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Christoph Rüthing, University of Paderborn
#   description:  The setup script to generate a complete EDK-Project
#                 from a base design, ther ReconOS components and the
#                 users HWTs.
# 
# ======================================================================

if [ $# -ne 1 ]
then
	echo "ERROR: No configuration file specified"
	exit
fi

echo "Generating EDK Projekt ..."

# source the specified configuration file
if [ ! -f $1 ]
then
	echo "ERROR: Configuration file not found"
	exit
fi
. ./$1

if [ -z "$num_reconf_hwts" ]
then
	num_reconf_hwts=0
	num_reconf_regions=0
fi
if [ -z "$num_static_hwts" ]
then
	num_static_hwts=0
fi
if [ $num_reconf_regions -gt 14 ]
then
	echo "WARNING: you have specified more than 14 reconfigurable regions."
	echo "         Since the default ucf contains only presets for 14 reconfigurable regions"
	echo "         you must specify your own area groups."

fi
num_hwts=$(($num_static_hwts+$num_reconf_regions))

echo "Copying base design and ReconOS hardware ..."

edk=edk_${RECONOS_ARCH}_${RECONOS_OS}

# copy base design and pcores
cp -r ${RECONOS}/designs/${RECONOS_ARCH}_${RECONOS_OS}_${base_design} $edk
mkdir -p $edk/pcores
cp -r ${RECONOS}/pcores/* $edk/pcores

echo "Generating ReconOS system ..."

# generate all files
find $edk/pcores -type f -exec reconos_preproc.sh {} $num_hwts {} \;

echo "Linking in HWTs ..."

# link HWTs to EDK
cd $edk/pcores

for hwt in $static_hwts
do
	ln -sf ../../${hwt%#*} .
done

for hwt in $reconf_hwts
do
	ln -sf ../../${hwt%#*} .
done

cd ../..

# generate mhs
cd $edk

mv system.mhs system.mhs.orig

if [ $num_reconf_hwts -ne 0 ]
then
	# create mhs files
	python ${RECONOS}/tools/python/mhsaddhwts.py "-reconf" $RECONOS_ARCH system.mhs.orig $num_static_hwts $num_reconf_regions $static_hwts "reconos_hwt_idle_v1_00_a" > system_static.mhs
	ln -s system_static.mhs system.mhs

	for hwt in $reconf_hwts
	do
		python ${RECONOS}/tools/python/mhsaddhwts.py "-reconf" $RECONOS_ARCH system.mhs.orig $num_static_hwts $num_reconf_regions $static_hwts $hwt > system_reconf_$hwt.mhs
	done

	# create system.ucf
	for i in $(seq 0 $(($num_reconf_regions-1)))
	do
		sed -i "s/#INST \"hwt_reconf_$i\"/INST \"hwt_reconf_$i\"/" data/system.ucf
		sed -i "s/#AREA_GROUP \"pblock_hwt_reconf_$i\"/AREA_GROUP \"pblock_hwt_reconf_$i\"/" data/system.ucf
	done
else
	# create mhs file
	if $RECONOS_MMU
	then
		python ${RECONOS}/tools/python/mhsaddhwts.py $RECONOS_ARCH system.mhs.orig $num_static_hwts 0 $static_hwts > system.mhs
	else
		python ${RECONOS}/tools/python/mhsaddhwts.py "-nommu" $RECONOS_ARCH system.mhs.orig $num_static_hwts 0 $static_hwts > system.mhs
	fi
fi
