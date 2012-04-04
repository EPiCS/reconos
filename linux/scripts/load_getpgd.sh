#!/bin/sh

# Copyright 2012 Andreas Agne <agne@upb.de>
# Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>

mname="getpgd"
cp ./$mname.ko /lib/modules/`uname -r`/
rmmod $mname
rm -f /dev/$mname
insmod $mname.ko
minor=`cat /sys/devices/virtual/misc/$mname/dev | sed -e 's/10://'`
mknod /dev/$mname c 10 $minor
