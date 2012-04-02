#!/bin/sh

mname="getpgd"
cp ./$mname.ko /lib/modules/`uname -r`/
rmmod $mname
rm -f /dev/$mname
insmod $mname.ko
minor=`cat /sys/devices/virtual/misc/$mname/dev | sed -e 's/10://`
mknod /dev/$mname c 10 $minor
