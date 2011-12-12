#!/bin/sh

MODULE="getpgd"
DEVICE="getpgd"

# invoke insmod with all arguments we got
# and use a pathname, as newer modutils don't look in . by default

rmmod $MODULE.ko
/sbin/insmod ./$MODULE.ko $* || exit 1

# remove stale nodes
rm -f /dev/$DEVICE

MAJOR=$(grep $MODULE /proc/devices)
MAJOR=${MAJOR% $MODULE}

mknod /dev/$DEVICE c $MAJOR 0

# give appropriate group/permissions, and change the group.
# Not all distributions have staff, some have "wheel" instead.



