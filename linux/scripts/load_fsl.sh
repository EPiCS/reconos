#!/bin/sh

# Example for 16 FSLs: 
#interrupt_list=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
# Example for 4 FSLs:
#interrupt_list=0,1,2,3
# Example for using FSLs 4 to 8 using interrupts 10 to 14:
#interrupt_list=-1,-1,-1,-1,10,11,12,13,14,-1,-1,-1,-1,-1,-1,-1

mname="fsl"
cp ./$mname.ko /lib/modules/`uname -r`/
rmmod $mname
if [ -z $interrupt_list ]
then
	numfsl=`./readpvr -V NUMFSL`
	numfsl=`expr $numfsl - 1`
	interrupts=`seq 0 $numfsl`
	interrupt_list=`echo $interrupts | tr ' ' ','`
else
	interrupts=`echo $interrupt_list | tr ',' ' '`
fi
insmod $mname.ko fsl_interrupts=$interrupt_list
i=0
for n in $interrupts
do
	if [ $n = -1 ]
	then
		i=`expr $i + 1`
		continue
	fi
	rm -f /dev/$mname$i
	minor=`cat /sys/devices/virtual/misc/$mname$i/dev | sed -e 's/10://'`
	mknod /dev/$mname$i c 10 $minor
	i=`expr $i + 1`
done
