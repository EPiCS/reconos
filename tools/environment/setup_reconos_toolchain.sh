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
#   description:  The main setup-script to setup the ReconOS Toolchain.
# 
# ======================================================================

echo "Setting up ReconOS toolchain ..."

reconos=`dirname $BASH_SOURCE`/../..
reconos=`cd $reconos && pwd`
echo "ReconOS path: $reconos"


# parsing arguments

if [ $# -ne 0 ]
then
	if [ ! -z "${1%%-*}" ]
	then
		echo "Using Configuration $1"
		config=$reconos/tools/environment/$1.sh
		OPTIND=2
	fi
fi

if [ -z "$config" ]
then
	echo "Using default configuration"
	config=$reconos/tools/environment/default.sh
fi

compile=false
while getopts c opt
do
	case $opt in
		c) compile=true;;
	esac
done

if [ -e $config ]
then
	. $config
else
	echo "ERROR: Configuration $config does not exists"
	return
fi

# add gnutools to path
export PATH=$gnutools/..:$PATH
export CROSS_COMPILE=$gnutools
if [ -z "$ARCH" ]
then
	case $reconos_arch in
		"microblaze")
			export ARCH="microblaze"
			;;
		"zynq")
			export ARCH="arm"
			;;
		*)
			echo "ERROR: Architecture not supported"
			return
			;;
	esac
fi


# source Xilinx Tools
. $xil_tools/ISE_DS/settings64.sh "$xil_tools/ISE_DS" > /dev/null

# export enviornment variables
export RECONOS=$reconos
export RECONOS_ARCH=$reconos_arch
export RECONOS_OS=$reconos_os
export RECONOS_MMU=$reconos_mmu

# add scripts to path
export PATH=$reconos/tools:$PATH

if $compile
then
	echo "Compiling ReconOS components ..."
	curr=`pwd`

	cd $reconos/$reconos_os/driver
	make clean > /dev/null
	make > /dev/null

	cd $reconos/$reconos_os/libreconos
	make clean > /dev/null
	make > /dev/null

	cd $curr
fi

echo "ReconOS setup finished successfully"

