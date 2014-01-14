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
#   description:  This script initializes ReconOS on your linux system.
#                 It loads the needed modules and ceates the device files.
# 
# ======================================================================

echo "Loading kernel module ..."
mkdir -p /lib/modules/`uname -r`
rmmod mreconos
insmod mreconos.ko

echo ""

echo "Creating device files ..."
if [ -d "/dev/reconos" ]
then
	rm -r /dev/reconos
fi
mkdir -p /dev/reconos

for dir in /sys/class/misc/reconos-*
do
	minor=`cat $dir/dev`
	minor=${minor##*:}
	devname=${dir#*-}

	echo "  /dev/reconos/$devname with 10:$minor"
	mknod /dev/reconos/$devname c 10 $minor
done

echo ""

echo "ReconOS setup finished successfully"

