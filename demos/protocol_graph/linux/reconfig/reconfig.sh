#!/bin/bash

old_val=0
new_val=0
while read -a line
do
	if [ "${line[0]}" == "cpu" ]; then
	#	echo "${line[4]}"
		old_val=${line[4]}
	
	fi
#	for word in $line; do
#		echo "word = '$word'";
#	done
done < /proc/stat

while true; do
	sleep 1

	while read -a line
	do
		if [ "${line[0]}" == "cpu" ]; then
		new_val=${line[4]}
	
		fi
	done < /proc/stat

	diff=$((new_val-$old_val));
	echo $diff >> cpu_idle.txt;
	old_val=$new_val;
	
	if [ $diff -lt 30 ]; then
		"./fbctl flag aes hw"
	fi
	if [ $diff -gt 70 ]; then
		"./fbctl unflag aes hw"
	fi
done

#test = awk '{if ($1 =="cpu") print $1}' /proc/stat 
#echo $test;
