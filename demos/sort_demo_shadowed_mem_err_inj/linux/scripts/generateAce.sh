#/bin/bash

# Possible parameters to "-cpu_version"  are: microblaze_v8be, microblaze_v8le, microblaze_v72
# However, microblaze_v8be and microblaze_v8le both create little endian output in the ace file
# Only "microblaze_v72" creates the big endian output needed for PLB based system

# Check command line parameters
if [ -z "$1" ]; then
    echo "Usage: $0 <path to bitstream>"
    exit 1
fi

KERNEL_PATH="/home/meise/git/linux-2.6-xlnx/arch/microblaze/boot"
#KERNEL_PATH="."

LD_PRELOAD="" LANG="" LANGUAGE="" LC_ALL="" xmd -tcl genace.tcl -jprog -target mdm -board ml605 -hw $1 -elf $KERNEL_PATH/simpleImage.ml605_epics_first_board  -ace linux_first_board.ace -cpu_version microblaze_v72  #-start_address 0x00000000
LD_PRELOAD="" LANG="" LANGUAGE="" LC_ALL="" xmd -tcl genace.tcl -jprog -target mdm -board ml605 -hw $1 -elf $KERNEL_PATH/simpleImage.ml605_epics_second_board -ace linux_second_board.ace -cpu_version microblaze_v72 #-start_address 0x00000000
LD_PRELOAD="" LANG="" LANGUAGE="" LC_ALL="" xmd -tcl genace.tcl -jprog -target mdm -board ml605 -hw $1 -elf $KERNEL_PATH/simpleImage.ml605_epics_third_board  -ace linux_third_board.ace -cpu_version microblaze_v72
LD_PRELOAD="" LANG="" LANGUAGE="" LC_ALL="" xmd -tcl genace.tcl -jprog -target mdm -board ml605 -hw $1 -elf $KERNEL_PATH/simpleImage.ml605_epics_fourth_board  -ace linux_fourth_board.ace -cpu_version microblaze_v72
