#!/bin/bash

# Script to automtically update the device tree in the linux 
# kernel and recompile the kernel.

print_help(){
    program_name=$(basename $0)
    echo "Usage:"
    echo -e "$program_name -h \t\tPrints this help message."
    echo -e "$program_name <project_dir> <linux_dir>"
}


#check inputs
if [ "$1" = "-h" -o "$1" = "--help" ]; then
    print_help;
    exit 0;
fi;

if [ "$1" = "" -o "$2" = "" ]; then
    echo "ERROR: Not enough arguments!";
    print_help;
    exit 1;
fi;
    
project_dir="$1"
linux_dir="$2"

echo -e "project directory:\t$project_dir"
echo -e "linux directory:\t$linux_dir"

#save old linux device tree
if [ -f "$linux_dir/arch/microblaze/boot/dts/ml605_epics.dts" ]; then
    cp "$linux_dir/arch/microblaze/boot/dts/ml605_epics.dts"  "$linux_dir/arch/microblaze/boot/dts/ml605_epics.dts.orig"
fi;

#copy new device tree
if [ -f "$project_dir/edk/microblaze_0/libsrc/device-tree_v0_00_x/xilinx.dts" ]; then
    cp "$project_dir/edk/microblaze_0/libsrc/device-tree_v0_00_x/xilinx.dts" "$linux_dir/arch/microblaze/boot/dts/ml605_epics.dts" 
else
    echo "ERROR: New device tree not found. Generate software and bsp in XPS."
    echo "TODO: Automate this..."
    exit 1;
fi;

#compile kernel 
(
 cd $linux_dir
 make ARCH=microblaze CROSS_COMPILE=microblaze-unknown-linux-gnu- simpleImage.ml605_epics
)