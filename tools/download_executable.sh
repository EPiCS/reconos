#!/bin/bash -i

# Called from $RECONOS/tools/dow
# Parameters: download_executable.sh <elf file> [esn] [cpu nr]
#        - the esn (electronic serial number) specifies which board to program.
#          A 0 here choose auto selection of a board
#        - cpu nr specifies which cpu to program, if there are several in your design

LAST_ELF_FILE="/tmp/.xmd_download_last"

# FIXME: default architecture is microblaze
if [ -z "$ARCH" ]; then
    ARCH="mb"
fi

# ELF file handling
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

# determine which programming adapter or board to use
if [  -n "$2"  -a  "0" != "$2"  ]
then
    ESN="$2"
    PORT_SPEC="-cable type xilinx_platformusb esn $ESN frequency 12000000"
    echo "Using programming adapter/board with ESN= $ESN."
else
    ESN="0"
    PORT_SPEC="-cable type xilinx_platformusb port usb21 frequency 12000000"
    echo "Using auto-detection for programming adapter/board."
fi


if [ "$ARCH" = "ppc" ]; then
    DOWCMD="ppccon\ndow $ELF\nrun\n"
elif [ "$ARCH" = "mb" ]; then
    if [ -z $3 ]; then 
        echo "Programming master CPU."
        DOWCMD="connect mb mdm $PORT_SPEC \ndow $ELF\nrun\n"
    else
        echo "Programming slave CPU nr. $3."
        DOWCMD="connect mb mdm $PORT_SPEC -debugdevice cpunr $3 \n\
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
	
