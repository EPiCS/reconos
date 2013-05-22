#!/bin/bash -i

# Called from $RECONOS/tools/dow
# Parameters: download_executable.sh <elf file> [cpu nr]

LAST_ELF_FILE="/tmp/.xmd_download_last"

# FIXME: default architecture is microblaze
if [ -z "$ARCH" ]; then
    ARCH="mb"
fi


if [ "$1" ]; then		# ELF provided on command line
	RETVAL="$1"
else
	if [ -f $LAST_ELF_FILE ]; then
	  ELF=`cat $LAST_ELF_FILE`
	else
	  ELF=$HOME
	fi

	RETVAL=`zenity --title "Select ELF" --entry --text="Please enter the ELF filename" --entry-text="${ELF}" --width=500`
fi

if [ ! -f $RETVAL ]; then
  echo "The file $RETVAL does not exist!"
  exit 1
else
  ELF=$RETVAL
fi

if [ "$ARCH" = "ppc" ]; then
    DOWCMD="ppccon\ndow $ELF\nrun\n"
elif [ "$ARCH" = "mb" ]; then
    if [ -z $2 ]; then 
        echo "Programming master CPU."
        DOWCMD="connect mb mdm\ndow $ELF\nrun\n"
    else
        echo "Programming slave CPU nr. $2."
        DOWCMD="connect mb mdm -debugdevice cpunr $2 \n\
 debugconfig -reset_on_data_dow processor enable \n\
 debugconfig -reset_on_run processor enable \n\
 rst -processor \n\
 dow $ELF \n\
 run \n"
    fi      
else
    echo "unknown ARCH '$ARCH'"
    exit 1
fi

if [ -e "$XILINX_EDK/bin/lin64/xmd" ] ; then
        echo -e $DOWCMD | $XILINX_EDK/bin/lin64/xmd
else
        echo -e $DOWCMD | $XILINX_EDK/bin/lin/xmd
fi
	
