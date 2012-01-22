#!/bin/sh

MODULE="fsl"
DEVICE="fsl"

# Example for 16 FSLs: 
#INTERRUPT_LIST=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

# Example for 4 FSLs:
#INTERRUPT_LIST=0,1,2,3

# Example for using FSLs 4 to 8 using interrupts 10 to 14:
#INTERRUPT_LIST=-1,-1,-1,-1,10,11,12,13,14,-1,-1,-1,-1,-1,-1,-1


# Automatic generation of interrupt list. This assumes that
# FSL interrupts start at 0 and end at NUMFSL-1. Also, each
# FSL must have an interrupt connected to the CPU.

if [ -z $INTERRUPT_LIST ]
then
	echo "No interrupt list supplied by user. Using defaults with auto detection."
	NUMFSL=$(./readpvr NUMFSL)
	NUMFSL=${NUMFSL#NUMFSL:}
	NUMFSL=$(expr $NUMFSL - 1)
	INTERRUPTS=$(seq  0 $NUMFSL)
	INTERRUPT_LIST=$(echo $INTERRUPTS | tr ' ' ',')
else
	echo "Using supplied interrupt list"
	INTERRUPTS=$(echo $INTERRUPT_LIST | tr ',' ' ')
fi

# invoke insmod with all arguments we got
# and use a pathname, as newer modutils don't look in . by default

mkdir -p /lib/modules/$(uname -r)
cp /fsl.ko /lib/modules/$(uname -r)

echo "removing module"
rmmod $MODULE

echo "inserting module"
modprobe $MODULE fsl_interrupts=$INTERRUPT_LIST

# remove stale nodes
echo "removing stale device nodes"
rm -f /dev/$DEVICE*

MAJOR=$(grep $DEVICE /proc/devices)
MAJOR=${MAJOR% $DEVICE}

echo "MAJOR=$MAJOR"

i=0
for n in $INTERRUPTS
do
	if [ $n = -1 ]
	then
		i=$(expr $i + 1)
		continue
	fi
	echo "creating device node /dev/$DEVICE$i"
	mknod /dev/$DEVICE$i c $MAJOR $i
	i=$(expr $i + 1)
done

# give appropriate group/permissions, and change the group.
# Not all distributions have staff, some have "wheel" instead.



