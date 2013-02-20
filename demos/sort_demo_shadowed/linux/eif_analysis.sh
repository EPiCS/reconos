#!/bin/bash

file=$1
TOTAL=`cat $file |wc -l `
echo "Total lines in file: $TOTAL"

for i in 0 1 2 4 16 32 127 132 134 137 139 143; do
    TEMP=`cat $file  | awk "/^$i$/ {nothing++}; END {print(nothing)}"`
    echo -e "$i \t\t $TEMP"
done;

REMAINDER=`cat $file | grep -v -e "^0$" -e "^1$" -e "^2$" -e "^4$" -e "^16$" -e "^32$"  -e "^132$"  -e "^134$" -e "^137$"  -e "^139$"  -e "^143$"`
echo "Unknown exit values:"
echo $REMAINDER

#SIG0=`cat $file  | awk '/^0$/ {nothing++}; END {print(nothing)}'`
#SIG1=`cat $file  | awk '/^1$/ {nothing++}; END {print(nothing)}'`
#SIG2=`cat $file  | awk '/^2$/ {nothing++}; END {print(nothing)}'`
#SIG4=`cat $file  | awk '/^4$/ {nothing++}; END {print(nothing)}'`
#SIG16=`cat $file  | awk '/^16$/ {nothing++}; END {print(nothing)}'`
#SIG32=`cat $file  | awk '/^32$/ {nothing++}; END {print(nothing)}'`
#SIG127=`cat $file  | awk '/^127$/ {nothing++}; END {print(nothing)}'`
#SIG132=`cat $file  | awk '/^132$/ {nothing++}; END {print(nothing)}'`
#SIG134=`cat $file  | awk '/^134$/ {nothing++}; END {print(nothing)}'`
#SIG137=`cat $file  | awk '/^137$/ {nothing++}; END {print(nothing)}'`
#SIG139=`cat $file  | awk '/^139$/ {nothing++}; END {print(nothing)}'`
#SIG143=`cat $file  | awk '/^143$/ {nothing++}; END {print(nothing)}'`

#REMAINDER=`cat $file | grep -v -e "^0$" -e "^1$" -e "^2$" -e "^4$" -e "^16$" -e "^32$"  -e "^132$"  -e "^134$" -e "^137$"  -e "^139$"  -e "^143$"`


