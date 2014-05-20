#!/bin/bash
#
#                                                        ____  _____
#                            ________  _________  ____  / __ \/ ___/
#                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
#                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
#                         /_/   \___/\___/\____/_/ /_/\____//____/
# 
# ======================================================================
# 
#   project:      ReconOS
#   author:       Christoph Rüthing, University of Paderborn
#   description:  Build the current edk project with reconfigurable HWTs
#                 an generates the full and partial bitstreams.
# 
# ======================================================================

set -e

xpartition()
{
	config=$1
	import=$2
	include_idle=$3

	xsts=`ls ../../../implementation/system_hwt_reconf_*.prj`

	echo '<?xml version="1.0"?>' >> xpartition.pxml
	echo '<Project Name="'$config'" FileVersion="1.2" ProjectVersion="2.0">' >> xpartition.pxml
	if [ $import -ne 0 ]
	then
		echo '  <Partition Name="/system" State="import" ImportLocation="../idle">' >> xpartition.pxml
	else
		echo '  <Partition Name="/system" State="implement" ImportLocation="NONE">' >> xpartition.pxml
	fi
	i=0
	for xst in $xsts
	do
		idle=`grep "reconos_hwt_idle" $xst || true`
		if [ -z "$idle" ]
		then
			echo '    <Partition Name="/system/hwt_reconf_'$i'" State="implement" ImportLocation="NONE" Reconfigurable="true" ReconfigModuleName="'$config'"></Partition>' >> xpartition.pxml
		else
			if [ $include_idle -eq 1 ]
			then
				echo '    <Partition Name="/system/hwt_reconf_'$i'" State="implement" ImportLocation="NONE" Reconfigurable="true" ReconfigModuleName="reconos_hwt_idle"></Partition>' >> xpartition.pxml
			fi
		fi

		i=$(($i+1))
	done
	echo '  </Partition>' >> xpartition.pxml
	echo '</Project>' >> xpartition.pxml
}

# figure out options
while getopts d opt
do
	case $opt in
		d) bitgenopt="-d";;
	esac
done


if [ ! -f system.xmp ]
then 
	echo "ERROR: Call this script from a EDK projekt folder"
	exit
fi

device=`grep "Device: " system.xmp | tr -d ' '`
device=${device#*:}

package=`grep "Package: " system.xmp | tr -d ' '`
package=${package#*:}

speedgrade=`grep "SpeedGrade: " system.xmp | tr -d ' '`
speedgrade=${speedgrade#*:}

part=$device$package$speedgrade

mhss=`ls system_reconf_*.mhs`


# create working directory

if [ -d reconos_reconf ]
then
	rm -rf reconos_reconf
fi

mkdir -p reconos_reconf/syn/static
mkdir -p reconos_reconf/syn/idle
mkdir -p reconos_reconf/data
cp data/system.ucf reconos_reconf/data


# generate netlists and implement design

# run netlist for static design and copy netlists
rm -f system.mhs
ln -fs system_static.mhs system.mhs

echo -e "run hwclean\nrun netlist\nexit\n" | xps -nw system

# copy over generated netlists
cp implementation/system_hwt_reconf*.ngc reconos_reconf/syn/idle
cp implementation/*.ngc reconos_reconf/syn/static
rm -f reconos_reconf/syn/static/system_hwt_reconf*

mkdir -p reconos_reconf/imp/idle
cd reconos_reconf/imp/idle


# generate xpartiton.pxml for idle design
xpartition "idle" 0 1

# implement idle design
ngdbuild -sd ../../syn/static -sd ../../syn/idle -uc ../../data/system.ucf ../../syn/static/system.ngc system.ngd
map -w -detail -ol high -mt 4 -timing -o system_map.ncd system.ngd system.pcf
par -w -ol high -mt 4 system_map.ncd system.ncd system.pcf
bitgen system.ncd system.bit system.pcf -w -g ActiveReconfig:Yes -g Binary:Yes -g ConfigFallback:Disable $bitgenopt

cd ../../..

# generate reconfigurable configs
for mhs in $mhss
do
	# determine config name
	config=${mhs%_v?_??_?.*}
	config=${config#system_reconf_}

	# create syn and imp directory
	mkdir -p reconos_reconf/syn/$config
	mkdir -p reconos_reconf/imp/$config

	# delete old hwt implementation
	rm -rf implementation/system_hwt_reconf*
	rm -rf implementation/cache/system_hwt_reconf*

	rm -f system.mhs
	ln -fs $mhs system.mhs
	# run netlist
	echo -e "run netlist\nexit\n" | xps -nw system

	# copy netlists
	cp implementation/system_hwt_reconf_*.ngc reconos_reconf/syn/$config

	cd reconos_reconf/imp/$config

	# generate xpartition.pxml
	xpartition $config 1 0

	ngdbuild -sd ../../syn/static -sd ../../syn/$config -uc ../../data/system.ucf ../../syn/static/system.ngc system.ngd
	map -w -detail -ol high -mt 4 -o system_map.ncd system.ngd system.pcf
	par -w -mt 4 system_map.ncd system.ncd system.pcf
	bitgen system.ncd system.bit system.pcf -w -g ActiveReconfig:Yes -g Binary:Yes -g ConfigFallback:Disable $bitgenopt

	cd ../../..
done

bins=`find reconos_reconf -iname *.bin -type f`
mkdir -p reconos_reconf/bin

for bin in $bins
do
	name=`basename $bin`
	reconos_revbin.sh $bin reconos_reconf/bin/$name
done

