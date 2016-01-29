#!/bin/bash
#
# Program for downloading bitstreams.
#
# Usage: download_bitstream.sh <bitfile> [jtag chain pos]
#        - jtag chain pos defaults to 3 (XUP)
#
# if $RECONOS_BOARD is set, jtag chain position is determined
# from there, if not specified
#
# If the environment variable IMPACT_REMOTE is set, it is used
# as a remotely running cse_server instead of a local USB connection


if [ -z $RECONOS_BOARD ]; then
    RECONOS_BOARD="ml605"
fi

echo "Assuming board '$RECONOS_BOARD'."

# select device to look for (XUP is default)
if [ "$RECONOS_BOARD" == "ml403" ]; then
    POS=2
elif [ "$RECONOS_BOARD" == "xup" ]; then
    POS=3
elif [ "$RECONOS_BOARD" == "ml605" ]; then
    POS=2
else
    echo "Unsupported board '$RECONOS_BOARD'."
    exit 1
fi

if [ $# -eq 2 ]
then
	POS=$2
fi

if [ -z $IMPACT_REMOTE ]; then

echo "
setMode -bs
setCable -port usb1 -b 12000000
Identify
IdentifyMPM
assignFile -p $POS -file \"$1\"
Program -p $POS
quit
" | impact -batch

else
echo "Using remote cs_server at ${IMPACT_REMOTE}"
echo "
setMode -bs
setCable -port auto -server ${IMPACT_REMOTE}
Identify
IdentifyMPM
assignFile -p $POS -file \"$1\"
Program -p $POS
quit
" | impact -batch

fi

# test for success
if [ $? -eq 0 ]; then
   echo "

SUCCESS
bitstream is $(($(date "+%s") - $(stat -c "%Y" $1))) seconds old" 

else
    echo "

FAILURE
could not download bitstream"
    exit 1
fi


