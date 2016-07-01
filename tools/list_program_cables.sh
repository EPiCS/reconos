#!/bin/bash
#
# Program for listing the programming cables and their ESNs.
#
# Usage: list_program:cables.sh 
#
# if $RECONOS_BOARD is set, jtag chain position is determined
# from there, if not specified
#
# If the environment variable IMPACT_REMOTE is set, it is used
# as a remotely running cse_server instead of a local USB connection




echo -e "listusbcables\nexit\n" | impact -batch | grep "port="




