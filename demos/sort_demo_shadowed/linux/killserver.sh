#!/bin/bash

while true; do
	# searches for lowest process id of a sort_demo_shadowed process
	oldpid=`ps aux | grep sort_demo_shadowed | grep -v grep | awk 'FNR==1 {print($2)}'`
	sleep 2
	newpid=`ps aux | grep sort_demo_shadowed | grep -v grep | awk 'FNR==1 {print($2)}'`
	
	# if the lowest process id of a sort_demo_shadowed task didn't change for a second,
	# we assume this task hangs and kill it.
	if [ -n "$oldpid" -a -n "$newpid" -a "$oldpid" == "$newpid" ]; then
		echo "Killing sort_demo_shadowed"
		kill -KILL $newpid
	fi
done
