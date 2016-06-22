#!/bin/sh

# This script includes the bootloader code for ReconOS worker CPUs into the bitstream

PROJECT="edk_worker"
BMM_FILE="hw/$PROJECT/implementation/system_bd.bmm"
ELF_FILE="hw/microblaze_v8_40_a/bootloader/Debug/bootloader.elf"
TAG_NAME="worker_0"
BIT_FILE="hw/$PROJECT/implementation/system.bit"
OUT_FILE="system_bootloader.bit"

data2mem -bm $BMM_FILE -bd $ELF_FILE tag $TAG_NAME -bt $BIT_FILE -o b $OUT_FILE -q SIWE
