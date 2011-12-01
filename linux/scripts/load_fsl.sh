#!/bin/sh

MODULE="fsl"
DEVICE="fsl"

INTERRUPT_LIST=0,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
INTERRUPTS=$(echo $INTERRUPT_LIST | tr ',' ' ')

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



