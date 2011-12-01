#!/bin/sh

MODULE="reconos"

DEVICE_OSIF="osif"
DEVICE_TLB="tlb"

# invoke insmod with all arguments we got
# and use a pathname, as newer modutils don't look in . by default

rmmod $MODULE.ko 
/sbin/insmod ./$MODULE.ko $* || exit 1

# remove stale nodes
rm -f /dev/$DEVICE_OSIF*
rm -f /dev/$DEVICE_TLB*

MAJOR_OSIF=$(grep $DEVICE_OSIF /proc/devices)
MAJOR_OSIF=${MAJOR_OSIF% $DEVICE_OSIF}

MAJOR_TLB=$(grep $DEVICE_TLB /proc/devices)
MAJOR_TLB=${MAJOR_TLB% $DEVICE_TLB}



for n in 0 1
do
	mknod /dev/$DEVICE_OSIF$n c $MAJOR_OSIF $n
done

mknod /dev/${DEVICE_TLB}0 c $MAJOR_TLB 0

# give appropriate group/permissions, and change the group.
# Not all distributions have staff, some have "wheel" instead.



