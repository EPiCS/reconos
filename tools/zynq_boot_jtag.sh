#!/bin/bash

# This is a simple script which helps you to boot the linux kernel
# on a Zynq board by using uImage and loading the linux kernel via
# TFTP.
# If you call it the first time you have to specify a uImage (the
# linux kernel), a compiled device tree blob, the ps7_init.tcl
# script and a u-boot executable.
# The last used files are cached by the script and can be reused
# the next time by calling the script with no parameters. This
# makes it easy to use because during the development cycle the
# needed files does not change very often.

cache="$RECONOS/cache/os_boot"
c_uimage="$cache/uImage"
c_dtb="$cache/devicetree.dtb"
c_init="$cache/ps7_init.tcl"
c_uboot="$cache/u-boot"

if [ ! -d $cache ]
then
	mkdir -p $cache
fi


if [ $# -ne 3 -a $# -ne 0  -a $# -ne 4 ]
then
	echo "ERROR: Wrong number of arguments."
	exit 0
fi


if [ $# -ge 3 ]
then
	uimage=$1
	dtb=$2
	init=$3

	cp $uimage $c_uimage
	cp $dtb $c_dtb
	cp $init $c_init

	if [ $# -eq 4 ]
	then
		uboot=$4
		cp $uboot $c_uboot
	else
		uboot=$c_uboot
	fi
else
	uimage=$c_uimage
	dtb=$c_dtb
	init=$c_init
	uboot=$c_uboot
	echo "No boot-files specified, using cached ones."
fi

echo "Booting Linux on Zynq ..."
echo "  Linux image (uImage):       $uimage"
echo "  Device-Tree-Blob:           $dtb"
echo "  Init-Skript (ps7_init.tcl): $init"
echo "  U-Boot executable:          $uboot"

echo -e "connect arm hw\nrst\nsource $init\nps7_init\nps7_post_config\ndow -data $dtb 0x02a00000\ndow -data $uimage 0x03000000\ndow $uboot\nrun" | xmd

